-- ============================================================================
-- ADMIN MESSAGING TO RUNNERS + PROVIDER ACCOUNTING RLS POLICIES
-- ============================================================================

-- ============================================================================
-- PART 1: Create admin messages table for runner communications
-- ============================================================================

-- Create admin_messages table for admin-to-runner communications
CREATE TABLE IF NOT EXISTS admin_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL means broadcast to all runners
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'general', -- 'general', 'announcement', 'warning', 'urgent'
    priority VARCHAR(20) DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadata
    sent_to_all_runners BOOLEAN DEFAULT FALSE,
    attachment_url TEXT,
    
    CONSTRAINT valid_message_type CHECK (message_type IN ('general', 'announcement', 'warning', 'urgent', 'info')),
    CONSTRAINT valid_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_admin_messages_recipient ON admin_messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_admin_messages_sender ON admin_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_admin_messages_created ON admin_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_messages_is_read ON admin_messages(is_read);

-- Add comment
COMMENT ON TABLE admin_messages IS 'Messages sent from admin to runners - supports individual and broadcast messages';

-- ============================================================================
-- PART 2: RLS Policies for admin_messages
-- ============================================================================

-- Enable RLS
ALTER TABLE admin_messages ENABLE ROW LEVEL SECURITY;

-- Policy 1: Admins can view all messages they sent
CREATE POLICY "Admins can view their sent messages"
    ON admin_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- Policy 2: Admins can insert messages
CREATE POLICY "Admins can send messages"
    ON admin_messages
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
        AND sender_id = auth.uid()
    );

-- Policy 3: Runners can view messages sent to them or broadcast messages
CREATE POLICY "Runners can view their messages"
    ON admin_messages
    FOR SELECT
    USING (
        (recipient_id = auth.uid() OR sent_to_all_runners = TRUE)
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND (users.user_type = 'runner' OR users.is_verified = TRUE)
        )
    );

-- Policy 4: Runners can update read status of their own messages
CREATE POLICY "Runners can mark messages as read"
    ON admin_messages
    FOR UPDATE
    USING (
        recipient_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND (users.user_type = 'runner' OR users.is_verified = TRUE)
        )
    )
    WITH CHECK (
        recipient_id = auth.uid()
    );

-- Policy 5: Admins can delete their own messages
CREATE POLICY "Admins can delete their messages"
    ON admin_messages
    FOR DELETE
    USING (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- ============================================================================
-- PART 3: RLS Policies for runner_earnings_summary view
-- ============================================================================

-- Note: Views inherit RLS from underlying tables, but we need to ensure proper access

-- Ensure users table has proper RLS for the view
-- Policy: Admins can view all users (needed for runner_earnings_summary)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'users' 
        AND policyname = 'Admins can view all users for accounting'
    ) THEN
        CREATE POLICY "Admins can view all users for accounting"
            ON users
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM users AS admin_user
                    WHERE admin_user.id = auth.uid() 
                    AND admin_user.user_type = 'admin'
                )
            );
    END IF;
END $$;

-- Policy: Runners can view their own user data
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'users' 
        AND policyname = 'Users can view own data'
    ) THEN
        CREATE POLICY "Users can view own data"
            ON users
            FOR SELECT
            USING (auth.uid() = id);
    END IF;
END $$;

-- Ensure errands table has proper RLS
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'errands' 
        AND policyname = 'Admins can view all errands for accounting'
    ) THEN
        CREATE POLICY "Admins can view all errands for accounting"
            ON errands
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM users 
                    WHERE users.id = auth.uid() 
                    AND users.user_type = 'admin'
                )
            );
    END IF;
END $$;

-- Ensure payments table has proper RLS
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'payments' 
        AND policyname = 'Admins can view all payments for accounting'
    ) THEN
        CREATE POLICY "Admins can view all payments for accounting"
            ON payments
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM users 
                    WHERE users.id = auth.uid() 
                    AND users.user_type = 'admin'
                )
            );
    END IF;
END $$;

-- Ensure transportation_bookings table has proper RLS
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'transportation_bookings' 
        AND policyname = 'Admins can view all transportation bookings for accounting'
    ) THEN
        CREATE POLICY "Admins can view all transportation bookings for accounting"
            ON transportation_bookings
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM users 
                    WHERE users.id = auth.uid() 
                    AND users.user_type = 'admin'
                )
            );
    END IF;
END $$;

-- Ensure contract_bookings table has proper RLS
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'contract_bookings' 
        AND policyname = 'Admins can view all contract bookings for accounting'
    ) THEN
        CREATE POLICY "Admins can view all contract bookings for accounting"
            ON contract_bookings
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM users 
                    WHERE users.id = auth.uid() 
                    AND users.user_type = 'admin'
                )
            );
    END IF;
END $$;

-- ============================================================================
-- PART 4: Create helper functions for admin messaging
-- ============================================================================

-- Function to send message to specific runner
CREATE OR REPLACE FUNCTION send_admin_message_to_runner(
    p_recipient_id UUID,
    p_subject VARCHAR,
    p_message TEXT,
    p_message_type VARCHAR DEFAULT 'general',
    p_priority VARCHAR DEFAULT 'normal'
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
        sent_to_all_runners
    ) VALUES (
        v_sender_id,
        p_recipient_id,
        p_subject,
        p_message,
        p_message_type,
        p_priority,
        FALSE
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

-- Function to broadcast message to all runners
CREATE OR REPLACE FUNCTION broadcast_admin_message_to_all_runners(
    p_subject VARCHAR,
    p_message TEXT,
    p_message_type VARCHAR DEFAULT 'announcement',
    p_priority VARCHAR DEFAULT 'normal'
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
    
    -- Create individual message for each runner
    FOR v_runner IN 
        SELECT id FROM users 
        WHERE user_type = 'runner' OR is_verified = TRUE
    LOOP
        -- Insert message
        INSERT INTO admin_messages (
            sender_id,
            recipient_id,
            subject,
            message,
            message_type,
            priority,
            sent_to_all_runners
        ) VALUES (
            v_sender_id,
            v_runner.id,
            p_subject,
            p_message,
            p_message_type,
            p_priority,
            TRUE
        );
        
        -- Also create a notification
        INSERT INTO notifications (
            user_id,
            title,
            message,
            type,
            is_read
        ) VALUES (
            v_runner.id,
            'Announcement: ' || p_subject,
            p_message,
            'admin_announcement',
            FALSE
        );
        
        v_count := v_count + 1;
    END LOOP;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark message as read
CREATE OR REPLACE FUNCTION mark_admin_message_as_read(p_message_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    UPDATE admin_messages
    SET is_read = TRUE,
        read_at = NOW(),
        updated_at = NOW()
    WHERE id = p_message_id
    AND recipient_id = v_user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION send_admin_message_to_runner TO authenticated;
GRANT EXECUTE ON FUNCTION broadcast_admin_message_to_all_runners TO authenticated;
GRANT EXECUTE ON FUNCTION mark_admin_message_as_read TO authenticated;

-- Grant permissions on admin_messages table
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_messages TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE admin_messages_id_seq TO authenticated;

COMMENT ON FUNCTION send_admin_message_to_runner IS 'Send a message from admin to a specific runner';
COMMENT ON FUNCTION broadcast_admin_message_to_all_runners IS 'Broadcast a message from admin to all runners';
COMMENT ON FUNCTION mark_admin_message_as_read IS 'Mark an admin message as read by the recipient';

