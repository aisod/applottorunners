-- ============================================================================
-- Fix Broadcast Logic + Add Chat Support for Admin Messages
-- October 10, 2025
-- ============================================================================

-- First, add the allow_reply column if it doesn't exist
ALTER TABLE admin_messages 
ADD COLUMN IF NOT EXISTS allow_reply BOOLEAN DEFAULT TRUE;

-- Add parent_message_id for threading/replies
ALTER TABLE admin_messages
ADD COLUMN IF NOT EXISTS parent_message_id UUID REFERENCES admin_messages(id) ON DELETE CASCADE;

-- Add index for parent message queries
CREATE INDEX IF NOT EXISTS idx_admin_messages_parent ON admin_messages(parent_message_id);

-- Update the broadcast function to create ONE message for all runners
CREATE OR REPLACE FUNCTION broadcast_admin_message_to_all_runners(
    p_subject VARCHAR,
    p_message TEXT,
    p_message_type VARCHAR DEFAULT 'announcement',
    p_priority VARCHAR DEFAULT 'normal',
    p_allow_reply BOOLEAN DEFAULT TRUE
)
RETURNS UUID AS $$
DECLARE
    v_sender_id UUID;
    v_message_id UUID;
    v_runner RECORD;
BEGIN
    -- Get current user (must be admin)
    v_sender_id := auth.uid();
    
    -- Verify sender is admin
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = v_sender_id AND user_type = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only admins can broadcast messages';
    END IF;
    
    -- Insert ONE broadcast message with recipient_id = NULL
    INSERT INTO admin_messages (
        sender_id,
        recipient_id,
        subject,
        message,
        message_type,
        priority,
        sent_to_all_runners,
        allow_reply
    ) VALUES (
        v_sender_id,
        NULL,  -- NULL means broadcast to all
        p_subject,
        p_message,
        p_message_type,
        p_priority,
        TRUE,
        p_allow_reply
    ) RETURNING id INTO v_message_id;
    
    -- Create notifications for each runner
    FOR v_runner IN 
        SELECT id 
        FROM users 
        WHERE (user_type = 'runner' OR is_verified = TRUE)
        AND id != v_sender_id
    LOOP
        INSERT INTO notifications (
            user_id,
            title,
            message,
            type,
            is_read
        ) VALUES (
            v_runner.id,
            'Broadcast from Admin: ' || p_subject,
            p_message,
            'admin_broadcast',
            FALSE
        );
    END LOOP;
    
    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update send_admin_message_to_runner to support threading
CREATE OR REPLACE FUNCTION send_admin_message_to_runner(
    p_recipient_id UUID,
    p_subject VARCHAR,
    p_message TEXT,
    p_message_type VARCHAR DEFAULT 'general',
    p_priority VARCHAR DEFAULT 'normal',
    p_allow_reply BOOLEAN DEFAULT TRUE,
    p_parent_message_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_message_id UUID;
    v_sender_id UUID;
BEGIN
    -- Get current user (must be admin)
    v_sender_id := auth.uid();
    
    -- Verify sender is admin
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = v_sender_id AND user_type = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only admins can send messages to runners';
    END IF;
    
    -- Verify recipient is a runner
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = p_recipient_id 
        AND (user_type = 'runner' OR is_verified = TRUE)
    ) THEN
        RAISE EXCEPTION 'Recipient must be a verified runner';
    END IF;
    
    -- Insert message
    INSERT INTO admin_messages (
        sender_id,
        recipient_id,
        subject,
        message,
        message_type,
        priority,
        sent_to_all_runners,
        allow_reply,
        parent_message_id
    ) VALUES (
        v_sender_id,
        p_recipient_id,
        p_subject,
        p_message,
        p_message_type,
        p_priority,
        FALSE,
        p_allow_reply,
        p_parent_message_id
    ) RETURNING id INTO v_message_id;
    
    -- Create notification only if not a reply
    IF p_parent_message_id IS NULL THEN
        INSERT INTO notifications (
            user_id,
            title,
            message,
            type,
            is_read
        ) VALUES (
            p_recipient_id,
            'Message from Admin: ' || p_subject,
            p_message,
            'admin_message',
            FALSE
        );
    END IF;
    
    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function for runners to reply to admin messages
CREATE OR REPLACE FUNCTION send_runner_reply_to_admin(
    p_parent_message_id UUID,
    p_message TEXT
)
RETURNS UUID AS $$
DECLARE
    v_message_id UUID;
    v_sender_id UUID;
    v_parent_message RECORD;
    v_admin_id UUID;
BEGIN
    -- Get current user (must be runner)
    v_sender_id := auth.uid();
    
    -- Get parent message details
    SELECT * INTO v_parent_message
    FROM admin_messages
    WHERE id = p_parent_message_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Parent message not found';
    END IF;
    
    -- Check if reply is allowed
    IF NOT v_parent_message.allow_reply THEN
        RAISE EXCEPTION 'Replies are not allowed for this message';
    END IF;
    
    -- Get admin ID (sender of original message)
    v_admin_id := v_parent_message.sender_id;
    
    -- Insert reply message
    INSERT INTO admin_messages (
        sender_id,
        recipient_id,
        subject,
        message,
        message_type,
        priority,
        sent_to_all_runners,
        allow_reply,
        parent_message_id
    ) VALUES (
        v_sender_id,
        v_admin_id,
        'Re: ' || v_parent_message.subject,
        p_message,
        'general',
        'normal',
        FALSE,
        TRUE,  -- Admin can always reply back
        p_parent_message_id
    ) RETURNING id INTO v_message_id;
    
    -- Create notification for admin
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read
    ) VALUES (
        v_admin_id,
        'Reply from Runner: ' || v_parent_message.subject,
        p_message,
        'runner_reply',
        FALSE
    );
    
    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get message thread (conversation)
CREATE OR REPLACE FUNCTION get_message_thread(p_message_id UUID)
RETURNS TABLE (
    id UUID,
    sender_id UUID,
    sender_name TEXT,
    sender_email TEXT,
    recipient_id UUID,
    recipient_name TEXT,
    subject TEXT,
    message TEXT,
    message_type VARCHAR,
    priority VARCHAR,
    is_read BOOLEAN,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    parent_message_id UUID,
    allow_reply BOOLEAN,
    sent_to_all_runners BOOLEAN
) AS $$
BEGIN
    -- Get the root message first
    WITH RECURSIVE message_tree AS (
        -- Base case: get the root message
        SELECT m.id, m.parent_message_id
        FROM admin_messages m
        WHERE m.id = p_message_id
        
        UNION ALL
        
        -- Recursive case: get parent messages
        SELECT m.id, m.parent_message_id
        FROM admin_messages m
        INNER JOIN message_tree mt ON m.id = mt.parent_message_id
    ),
    root_message AS (
        SELECT id FROM message_tree WHERE parent_message_id IS NULL
    )
    
    -- Return all messages in the thread
    RETURN QUERY
    SELECT 
        m.id,
        m.sender_id,
        u_sender.full_name AS sender_name,
        u_sender.email AS sender_email,
        m.recipient_id,
        u_recipient.full_name AS recipient_name,
        m.subject,
        m.message,
        m.message_type,
        m.priority,
        m.is_read,
        m.read_at,
        m.created_at,
        m.parent_message_id,
        m.allow_reply,
        m.sent_to_all_runners
    FROM admin_messages m
    LEFT JOIN users u_sender ON m.sender_id = u_sender.id
    LEFT JOIN users u_recipient ON m.recipient_id = u_recipient.id
    WHERE m.id IN (SELECT id FROM root_message)
       OR m.parent_message_id IN (SELECT id FROM root_message)
       OR m.id = p_message_id
    ORDER BY m.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies for runners to see broadcast messages
DROP POLICY IF EXISTS "Runners can view their messages" ON admin_messages;

CREATE POLICY "Runners can view their messages"
    ON admin_messages
    FOR SELECT
    USING (
        (
            -- Individual messages to them
            recipient_id = auth.uid() 
            -- Broadcast messages (recipient_id is NULL)
            OR (sent_to_all_runners = TRUE AND recipient_id IS NULL)
            -- Messages they sent (replies)
            OR sender_id = auth.uid()
        )
        AND (
            EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = auth.uid() 
                AND (users.user_type = 'runner' OR users.is_verified = TRUE)
            )
            OR EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = auth.uid() 
                AND users.user_type = 'admin'
            )
        )
    );

-- Update policy for runners to insert replies
DROP POLICY IF EXISTS "Runners can send replies" ON admin_messages;

CREATE POLICY "Runners can send replies"
    ON admin_messages
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND parent_message_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND (users.user_type = 'runner' OR users.is_verified = TRUE)
        )
    );

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION send_admin_message_to_runner TO authenticated;
GRANT EXECUTE ON FUNCTION broadcast_admin_message_to_all_runners TO authenticated;
GRANT EXECUTE ON FUNCTION send_runner_reply_to_admin TO authenticated;
GRANT EXECUTE ON FUNCTION get_message_thread TO authenticated;

-- Update existing broadcast messages to have recipient_id = NULL
UPDATE admin_messages
SET recipient_id = NULL
WHERE sent_to_all_runners = TRUE;

COMMENT ON COLUMN admin_messages.parent_message_id IS 'Links replies to original message for threading';
COMMENT ON FUNCTION get_message_thread IS 'Returns all messages in a conversation thread';
COMMENT ON FUNCTION send_runner_reply_to_admin IS 'Allows runners to reply to admin messages';

