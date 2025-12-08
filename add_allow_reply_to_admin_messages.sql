-- ============================================================================
-- Add allow_reply column to admin_messages table
-- October 10, 2025
-- ============================================================================

-- Add allow_reply column to control whether runners can reply
ALTER TABLE admin_messages 
ADD COLUMN IF NOT EXISTS allow_reply BOOLEAN DEFAULT TRUE;

-- Add comment
COMMENT ON COLUMN admin_messages.allow_reply IS 'Whether the runner can reply to this message';

-- Update existing messages to allow replies by default
UPDATE admin_messages 
SET allow_reply = TRUE 
WHERE allow_reply IS NULL;

-- Update the send_admin_message_to_runner function to include allow_reply
CREATE OR REPLACE FUNCTION send_admin_message_to_runner(
    p_recipient_id UUID,
    p_subject VARCHAR,
    p_message TEXT,
    p_message_type VARCHAR DEFAULT 'general',
    p_priority VARCHAR DEFAULT 'normal',
    p_allow_reply BOOLEAN DEFAULT TRUE
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
        allow_reply
    ) VALUES (
        v_sender_id,
        p_recipient_id,
        p_subject,
        p_message,
        p_message_type,
        p_priority,
        FALSE,
        p_allow_reply
    ) RETURNING id INTO v_message_id;
    
    -- Also create a notification
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
    
    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update broadcast function to include allow_reply
CREATE OR REPLACE FUNCTION broadcast_admin_message_to_all_runners(
    p_subject VARCHAR,
    p_message TEXT,
    p_message_type VARCHAR DEFAULT 'announcement',
    p_priority VARCHAR DEFAULT 'normal',
    p_allow_reply BOOLEAN DEFAULT TRUE
)
RETURNS INT AS $$
DECLARE
    v_sender_id UUID;
    v_runner RECORD;
    v_count INT := 0;
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
    
    -- Get all verified runners
    FOR v_runner IN 
        SELECT id 
        FROM users 
        WHERE (user_type = 'runner' OR is_verified = TRUE)
        AND id != v_sender_id
    LOOP
        -- Insert message for each runner
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
            v_runner.id,
            p_subject,
            p_message,
            p_message_type,
            p_priority,
            TRUE,
            p_allow_reply
        );
        
        -- Create notification for each runner
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
        
        v_count := v_count + 1;
    END LOOP;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION send_admin_message_to_runner TO authenticated;
GRANT EXECUTE ON FUNCTION broadcast_admin_message_to_all_runners TO authenticated;

