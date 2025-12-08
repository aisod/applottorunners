-- Admin RPC Functions for Lotto Runners
-- These functions bypass RLS for admin operations

-- Function to update user verification status
CREATE OR REPLACE FUNCTION update_user_verification(
    user_id UUID,
    is_verified BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only admins can update user verification status';
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

-- Function to update user role
CREATE OR REPLACE FUNCTION update_user_role(
    user_id UUID,
    new_role TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only admins can update user roles';
    END IF;
    
    -- Validate role
    IF new_role NOT IN ('admin', 'individual', 'business', 'runner') THEN
        RAISE EXCEPTION 'Invalid user role: %', new_role;
    END IF;
    
    -- Update the user
    UPDATE users 
    SET 
        user_type = new_role,
        updated_at = NOW()
    WHERE users.id = update_user_role.user_id;
    
    -- Return true if update was successful
    RETURN FOUND;
END;
$$;

-- Function to deactivate user
CREATE OR REPLACE FUNCTION deactivate_user(
    user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only admins can deactivate users';
    END IF;
    
    -- Update the user (assuming we have an is_active field or similar)
    -- For now, we'll just update the updated_at timestamp
    UPDATE users 
    SET 
        updated_at = NOW()
    WHERE users.id = deactivate_user.user_id;
    
    -- Return true if update was successful
    RETURN FOUND;
END;
$$;

-- Function to update runner application status and sync with users table
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
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only admins can update runner application status';
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

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION update_user_verification(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_role(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION deactivate_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_runner_application_status(UUID, TEXT, TEXT) TO authenticated;
