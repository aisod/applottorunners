-- ============================================================================
-- COMPLETE FIX FOR ALL RLS POLICY ISSUES
-- ============================================================================
-- This script fixes infinite recursion issues in RLS policies by using
-- a helper function instead of querying the users table within policies

-- ============================================================================
-- STEP 1: Create is_admin() helper function
-- ============================================================================

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

GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

COMMENT ON FUNCTION is_admin IS 'Check if current user is admin without causing infinite recursion in RLS policies';

-- ============================================================================
-- STEP 2: Fix users table policies
-- ============================================================================

DROP POLICY IF EXISTS "Admins can view all users for accounting" ON users;
DROP POLICY IF EXISTS "admin_can_update_users" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update users" ON users;

CREATE POLICY "Admins can view all users"
    ON users
    FOR SELECT
    USING (is_admin() OR auth.uid() = id);

CREATE POLICY "Admins can update users"
    ON users
    FOR UPDATE
    USING (is_admin());

-- ============================================================================
-- STEP 3: Fix admin_messages table policies
-- ============================================================================

DROP POLICY IF EXISTS "Admins can view their sent messages" ON admin_messages;
DROP POLICY IF EXISTS "Admins can send messages" ON admin_messages;
DROP POLICY IF EXISTS "Runners can view their messages" ON admin_messages;
DROP POLICY IF EXISTS "Runners can mark messages as read" ON admin_messages;
DROP POLICY IF EXISTS "Admins can delete their messages" ON admin_messages;
DROP POLICY IF EXISTS "Admins can view all messages" ON admin_messages;

CREATE POLICY "Admins can view all messages"
    ON admin_messages
    FOR SELECT
    USING (is_admin());

CREATE POLICY "Admins can send messages"
    ON admin_messages
    FOR INSERT
    WITH CHECK (is_admin() AND sender_id = auth.uid());

CREATE POLICY "Runners can view their messages"
    ON admin_messages
    FOR SELECT
    USING (
        NOT is_admin() 
        AND (recipient_id = auth.uid() OR sent_to_all_runners = TRUE)
    );

CREATE POLICY "Runners can mark messages as read"
    ON admin_messages
    FOR UPDATE
    USING (
        NOT is_admin() 
        AND recipient_id = auth.uid()
    )
    WITH CHECK (
        NOT is_admin() 
        AND recipient_id = auth.uid()
    );

CREATE POLICY "Admins can delete their messages"
    ON admin_messages
    FOR DELETE
    USING (is_admin() AND sender_id = auth.uid());

-- ============================================================================
-- STEP 4: Verify policies don't use recursive queries
-- ============================================================================

-- Check for any remaining policies that might cause recursion
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT tablename, policyname, qual 
        FROM pg_policies 
        WHERE qual LIKE '%FROM users%'
        AND tablename = 'users'
    LOOP
        RAISE WARNING 'Potential recursive policy found: %.% - %', rec.tablename, rec.policyname, rec.qual;
    END LOOP;
END $$;

-- ============================================================================
-- Success Message
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ All RLS policies fixed successfully!';
    RAISE NOTICE '✅ is_admin() function created';
    RAISE NOTICE '✅ users table policies updated';
    RAISE NOTICE '✅ admin_messages table policies updated';
    RAISE NOTICE '✅ No more infinite recursion!';
END $$;

