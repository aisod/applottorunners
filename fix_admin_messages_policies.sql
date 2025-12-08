-- Fix Admin Messages RLS Policies to Use is_admin() Function
-- This prevents infinite recursion issues

-- Drop old policies that cause recursion
DROP POLICY IF EXISTS "Admins can view their sent messages" ON admin_messages;
DROP POLICY IF EXISTS "Admins can send messages" ON admin_messages;
DROP POLICY IF EXISTS "Runners can view their messages" ON admin_messages;
DROP POLICY IF EXISTS "Runners can mark messages as read" ON admin_messages;
DROP POLICY IF EXISTS "Admins can delete their messages" ON admin_messages;

-- Recreate policies using is_admin() function (no recursion)
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

COMMENT ON POLICY "Admins can view all messages" ON admin_messages IS 'Admins can view all messages - uses is_admin() to avoid recursion';
COMMENT ON POLICY "Runners can view their messages" ON admin_messages IS 'Runners can view messages sent to them or broadcast messages';

