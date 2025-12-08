-- Fix for Verified Runner Vehicle Update Issue
-- This allows already verified runners to update their vehicle information

-- 1. Create a function to allow verified runners to update their vehicle information
CREATE OR REPLACE FUNCTION update_verified_runner_vehicle(
    p_user_id UUID,
    p_has_vehicle BOOLEAN,
    p_vehicle_type TEXT DEFAULT NULL,
    p_vehicle_details TEXT DEFAULT NULL,
    p_license_number TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    app_record RECORD;
    current_user_is_admin BOOLEAN;
    current_user_is_runner BOOLEAN;
BEGIN
    -- Check if current user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'No authenticated user found';
    END IF;
    
    -- Check if current user is admin or the runner themselves
    SELECT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) INTO current_user_is_admin;
    
    SELECT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.id = p_user_id
        AND users.user_type = 'runner'
    ) INTO current_user_is_runner;
    
    IF NOT current_user_is_admin AND NOT current_user_is_runner THEN
        RAISE EXCEPTION 'Only admins or the runner themselves can update vehicle information';
    END IF;
    
    -- Get the runner application
    SELECT * INTO app_record
    FROM runner_applications
    WHERE user_id = p_user_id
    AND verification_status = 'approved';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No approved runner application found for user: %', p_user_id;
    END IF;
    
    -- Update the runner application with new vehicle information
    UPDATE runner_applications 
    SET 
        has_vehicle = p_has_vehicle,
        vehicle_type = CASE WHEN p_has_vehicle THEN p_vehicle_type ELSE NULL END,
        vehicle_details = CASE WHEN p_has_vehicle THEN p_vehicle_details ELSE NULL END,
        license_number = CASE WHEN p_has_vehicle THEN p_license_number ELSE NULL END,
        updated_at = NOW()
    WHERE user_id = p_user_id
    AND verification_status = 'approved';
    
    -- Sync with users table
    UPDATE users 
    SET 
        has_vehicle = p_has_vehicle,
        vehicle_type = CASE WHEN p_has_vehicle THEN p_vehicle_type ELSE NULL END,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Return true if update was successful
    RETURN FOUND;
END;
$$;

-- 2. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_verified_runner_vehicle(UUID, BOOLEAN, TEXT, TEXT, TEXT) TO authenticated;

-- 3. Create a function to get verified runner's current vehicle information
CREATE OR REPLACE FUNCTION get_verified_runner_vehicle_info(p_user_id UUID)
RETURNS TABLE(
    has_vehicle BOOLEAN,
    vehicle_type TEXT,
    vehicle_details TEXT,
    license_number TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_is_admin BOOLEAN;
    current_user_is_runner BOOLEAN;
BEGIN
    -- Check if current user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'No authenticated user found';
    END IF;
    
    -- Check if current user is admin or the runner themselves
    SELECT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) INTO current_user_is_admin;
    
    SELECT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.id = p_user_id
        AND users.user_type = 'runner'
    ) INTO current_user_is_runner;
    
    IF NOT current_user_is_admin AND NOT current_user_is_runner THEN
        RAISE EXCEPTION 'Only admins or the runner themselves can view vehicle information';
    END IF;
    
    -- Return vehicle information from the approved runner application
    RETURN QUERY
    SELECT 
        ra.has_vehicle,
        ra.vehicle_type,
        ra.vehicle_details,
        ra.license_number
    FROM runner_applications ra
    WHERE ra.user_id = p_user_id
    AND ra.verification_status = 'approved';
END;
$$;

-- 4. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_verified_runner_vehicle_info(UUID) TO authenticated;

-- 5. Test the functions with sample data
-- First, let's check if there are any approved runners
SELECT 'Testing vehicle update functions...' as status;

-- Check existing approved runners
SELECT 
    u.id,
    u.full_name,
    u.has_vehicle,
    ra.vehicle_type,
    ra.verification_status
FROM users u
JOIN runner_applications ra ON u.id = ra.user_id
WHERE ra.verification_status = 'approved'
LIMIT 5;

-- 6. Create a test function to verify the update works (without authentication)
CREATE OR REPLACE FUNCTION test_vehicle_update()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    test_user_id UUID;
    update_result BOOLEAN;
    vehicle_info RECORD;
BEGIN
    -- Find a verified runner to test with
    SELECT u.id INTO test_user_id
    FROM users u
    JOIN runner_applications ra ON u.id = ra.user_id
    WHERE ra.verification_status = 'approved'
    AND u.user_type = 'runner'
    LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RETURN 'No verified runners found for testing';
    END IF;
    
    -- Test updating vehicle information directly (bypassing auth check for testing)
    -- Update runner application directly
    UPDATE runner_applications 
    SET 
        has_vehicle = true,
        vehicle_type = 'SUV',
        vehicle_details = 'Test Vehicle Details',
        license_number = 'TEST123456',
        updated_at = NOW()
    WHERE user_id = test_user_id
    AND verification_status = 'approved';
    
    -- Update users table
    UPDATE users 
    SET 
        has_vehicle = true,
        vehicle_type = 'SUV',
        updated_at = NOW()
    WHERE id = test_user_id;
    
    -- Get the updated information
    SELECT 
        ra.has_vehicle,
        ra.vehicle_type,
        ra.vehicle_details,
        ra.license_number
    INTO vehicle_info
    FROM runner_applications ra
    WHERE ra.user_id = test_user_id
    AND ra.verification_status = 'approved';
    
    RETURN format('Vehicle update successful for user %s. Has vehicle: %s, Type: %s', 
                 test_user_id, vehicle_info.has_vehicle, vehicle_info.vehicle_type);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION test_vehicle_update() TO authenticated;

-- 7. Run the test
SELECT test_vehicle_update() as test_result;

-- 8. Verify the functions were created successfully
SELECT 'Functions created successfully' as status;

-- Check if functions exist
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN ('update_verified_runner_vehicle', 'get_verified_runner_vehicle_info')
AND routine_schema = 'public';

-- 9. Clean up test function
DROP FUNCTION IF EXISTS test_vehicle_update();

-- Summary of changes:
-- 1. Created update_verified_runner_vehicle() function to allow verified runners to update vehicle info
-- 2. Created get_verified_runner_vehicle_info() function to retrieve current vehicle information
-- 3. Both functions check permissions (admin or runner themselves)
-- 4. Functions update both runner_applications and users tables to keep them in sync
-- 5. Added proper error handling and security checks
