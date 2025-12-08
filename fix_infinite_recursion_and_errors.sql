-- ============================================================================
-- FIX INFINITE RECURSION IN USERS TABLE RLS POLICIES
-- ============================================================================

-- Drop the problematic policies that cause infinite recursion
DROP POLICY IF EXISTS "Admins can view all users for accounting" ON users;
DROP POLICY IF EXISTS "admin_can_update_users" ON users;

-- Create a function to check if user is admin (avoids recursion)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
DECLARE
    user_type_val TEXT;
BEGIN
    -- Get user_type directly from users table
    SELECT u.user_type INTO user_type_val
    FROM public.users u
    WHERE u.id = auth.uid()
    LIMIT 1;
    
    -- Return true if user_type is 'admin'
    RETURN COALESCE(user_type_val = 'admin', FALSE);
EXCEPTION
    WHEN OTHERS THEN
        -- If any error occurs, return false
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Recreate policies using the function (no recursion)
CREATE POLICY "Admins can view all users"
    ON users
    FOR SELECT
    USING (is_admin() OR auth.uid() = id);

CREATE POLICY "Admins can update users"
    ON users
    FOR UPDATE
    USING (is_admin());

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

COMMENT ON FUNCTION is_admin IS 'Check if current user is admin without causing infinite recursion';

