-- Comprehensive fix for verification issues
-- This script addresses common causes of verification failures

-- 1. Ensure RPC functions exist and are properly configured
CREATE OR REPLACE FUNCTION update_user_verification(
    user_id UUID,
    is_verified BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_user_exists BOOLEAN;
    current_user_is_admin BOOLEAN;
BEGIN
    -- Check if current user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'No authenticated user found';
    END IF;
    
    -- Check if current user is admin
    SELECT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) INTO current_user_is_admin;
    
    IF NOT current_user_is_admin THEN
        RAISE EXCEPTION 'Only admins can update user verification status. Current user type: %', 
            (SELECT user_type FROM users WHERE id = auth.uid());
    END IF;
    
    -- Check if target user exists
    SELECT EXISTS (
        SELECT 1 FROM users WHERE users.id = update_user_verification.user_id
    ) INTO target_user_exists;
    
    IF NOT target_user_exists THEN
        RAISE EXCEPTION 'Target user not found with ID: %', update_user_verification.user_id;
    END IF;
    
    -- Update the user
    UPDATE users 
    SET 
        is_verified = update_user_verification.is_verified,
        updated_at = NOW()
    WHERE users.id = update_user_verification.user_id;
    
    -- Also sync runner applications if user has any
    UPDATE runner_applications 
    SET 
        verification_status = CASE 
            WHEN update_user_verification.is_verified THEN 'approved'
            ELSE 'rejected'
        END,
        reviewed_at = NOW(),
        reviewed_by = auth.uid()
    WHERE runner_applications.user_id = update_user_verification.user_id;
    
    -- Return true if update was successful
    RETURN FOUND;
END;
$$;

-- 2. Create or replace the runner application status function
CREATE OR REPLACE FUNCTION update_runner_application_status(
    application_id UUID,
    status TEXT,
    notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    app_user_id UUID;
    app_has_vehicle BOOLEAN;
    app_vehicle_type TEXT;
    current_user_is_admin BOOLEAN;
BEGIN
    -- Check if current user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'No authenticated user found';
    END IF;
    
    -- Check if current user is admin
    SELECT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) INTO current_user_is_admin;
    
    IF NOT current_user_is_admin THEN
        RAISE EXCEPTION 'Only admins can update runner application status. Current user type: %', 
            (SELECT user_type FROM users WHERE id = auth.uid());
    END IF;
    
    -- Validate status
    IF status NOT IN ('pending', 'approved', 'rejected') THEN
        RAISE EXCEPTION 'Invalid status: %. Must be pending, approved, or rejected', status;
    END IF;
    
    -- Get application details
    SELECT user_id, has_vehicle, vehicle_type
    INTO app_user_id, app_has_vehicle, app_vehicle_type
    FROM runner_applications
    WHERE id = application_id;
    
    IF app_user_id IS NULL THEN
        RAISE EXCEPTION 'Runner application not found with ID: %', application_id;
    END IF;
    
    -- Update the runner application
    UPDATE runner_applications 
    SET 
        verification_status = update_runner_application_status.status,
        notes = update_runner_application_status.notes,
        reviewed_at = NOW(),
        reviewed_by = auth.uid()
    WHERE id = application_id;
    
    -- Sync with users table
    UPDATE users 
    SET 
        is_verified = (status = 'approved'),
        has_vehicle = COALESCE(app_has_vehicle, false),
        vehicle_type = app_vehicle_type,
        updated_at = NOW()
    WHERE id = app_user_id;
    
    -- Return true if update was successful
    RETURN FOUND;
END;
$$;

-- 3. Grant execute permissions
GRANT EXECUTE ON FUNCTION update_user_verification(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION update_runner_application_status(UUID, TEXT, TEXT) TO authenticated;

-- 4. Check and fix RLS policies if needed
-- First, let's see what policies exist
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- 5. Create a comprehensive admin policy if it doesn't exist
-- This policy allows admins to update any user's verification status
DO $$
BEGIN
    -- Check if admin policy exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'users' 
        AND policyname = 'admin_can_update_users'
    ) THEN
        -- Create admin policy
        EXECUTE 'CREATE POLICY admin_can_update_users ON users
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM users admin_user 
                    WHERE admin_user.id = auth.uid() 
                    AND admin_user.user_type = ''admin''
                )
            )';
        
        RAISE NOTICE 'Created admin policy for users table';
    ELSE
        RAISE NOTICE 'Admin policy already exists for users table';
    END IF;
END $$;

-- 6. Create admin policy for runner_applications if it doesn't exist
DO $$
BEGIN
    -- Check if admin policy exists for runner_applications
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'runner_applications' 
        AND policyname = 'admin_can_update_runner_applications'
    ) THEN
        -- Create admin policy for runner_applications
        EXECUTE 'CREATE POLICY admin_can_update_runner_applications ON runner_applications
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM users admin_user 
                    WHERE admin_user.id = auth.uid() 
                    AND admin_user.user_type = ''admin''
                )
            )';
        
        RAISE NOTICE 'Created admin policy for runner_applications table';
    ELSE
        RAISE NOTICE 'Admin policy already exists for runner_applications table';
    END IF;
END $$;

-- 7. Test the functions
-- This will help verify everything is working
DO $$
DECLARE
    test_result BOOLEAN;
    test_user_id UUID;
BEGIN
    -- Find a test user (replace with actual user ID if needed)
    SELECT id INTO test_user_id 
    FROM users 
    WHERE user_type != 'admin' 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user ID: %', test_user_id;
        
        -- Test the RPC function
        BEGIN
            SELECT update_user_verification(test_user_id, true) INTO test_result;
            RAISE NOTICE 'RPC function test result: %', test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'RPC function test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No test user found to test with';
    END IF;
END $$;
