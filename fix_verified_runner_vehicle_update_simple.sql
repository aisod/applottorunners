-- Simplified Fix for Verified Runner Vehicle Update Issue
-- This creates the necessary functions without authentication-dependent tests

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

-- 2. Create a function to get verified runner's current vehicle information
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

-- 3. Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION update_verified_runner_vehicle(UUID, BOOLEAN, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_verified_runner_vehicle_info(UUID) TO authenticated;

-- 4. Verify the functions were created successfully
SELECT 'Functions created successfully' as status;

-- Check if functions exist
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN ('update_verified_runner_vehicle', 'get_verified_runner_vehicle_info')
AND routine_schema = 'public';

-- 5. Show current verified runners (for reference)
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

-- Summary:
-- ✅ Created update_verified_runner_vehicle() function
-- ✅ Created get_verified_runner_vehicle_info() function  
-- ✅ Both functions include proper security checks
-- ✅ Functions update both runner_applications and users tables
-- ✅ Ready for use by verified runners through the Flutter app
