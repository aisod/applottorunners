-- Chat System RLS Policies
-- This script creates comprehensive Row Level Security policies for the chat system

-- Enable RLS on chat tables
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- CHAT_CONVERSATIONS TABLE POLICIES
-- ==============================================

-- Policy: Users can view conversations they are part of (both errand and transportation)
CREATE POLICY "Users can view their conversations" ON chat_conversations
FOR SELECT USING (
  auth.uid() = customer_id OR auth.uid() = runner_id
);

-- Policy: Users can create conversations for errands they own or are assigned to
CREATE POLICY "Users can create errand conversations" ON chat_conversations
FOR INSERT WITH CHECK (
  conversation_type = 'errand' AND 
  (auth.uid() = customer_id OR auth.uid() = runner_id) AND
  errand_id IS NOT NULL
);

-- Policy: Users can create conversations for transportation bookings they own or are assigned to
CREATE POLICY "Users can create transportation conversations" ON chat_conversations
FOR INSERT WITH CHECK (
  conversation_type = 'transportation' AND 
  (auth.uid() = customer_id OR auth.uid() = runner_id) AND
  transportation_booking_id IS NOT NULL
);

-- Policy: Users can update conversations they are part of
CREATE POLICY "Users can update their conversations" ON chat_conversations
FOR UPDATE USING (
  auth.uid() = customer_id OR auth.uid() = runner_id
) WITH CHECK (
  auth.uid() = customer_id OR auth.uid() = runner_id
);

-- Policy: Users can delete conversations they are part of (if needed)
CREATE POLICY "Users can delete their conversations" ON chat_conversations
FOR DELETE USING (
  auth.uid() = customer_id OR auth.uid() = runner_id
);

-- ==============================================
-- CHAT_MESSAGES TABLE POLICIES
-- ==============================================

-- Policy: Users can view messages in conversations they are part of
CREATE POLICY "Users can view messages in their conversations" ON chat_messages
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM chat_conversations cc 
    WHERE cc.id = chat_messages.conversation_id 
    AND (auth.uid() = cc.customer_id OR auth.uid() = cc.runner_id)
  )
);

-- Policy: Users can send messages in conversations they are part of
CREATE POLICY "Users can send messages in their conversations" ON chat_messages
FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1 FROM chat_conversations cc 
    WHERE cc.id = chat_messages.conversation_id 
    AND (auth.uid() = cc.customer_id OR auth.uid() = cc.runner_id)
  )
);

-- Policy: Users can update their own messages (for read status, etc.)
CREATE POLICY "Users can update their own messages" ON chat_messages
FOR UPDATE USING (
  auth.uid() = sender_id OR
  EXISTS (
    SELECT 1 FROM chat_conversations cc 
    WHERE cc.id = chat_messages.conversation_id 
    AND (auth.uid() = cc.customer_id OR auth.uid() = cc.runner_id)
  )
) WITH CHECK (
  auth.uid() = sender_id OR
  EXISTS (
    SELECT 1 FROM chat_conversations cc 
    WHERE cc.id = chat_messages.conversation_id 
    AND (auth.uid() = cc.customer_id OR auth.uid() = cc.runner_id)
  )
);

-- Policy: Users can delete their own messages
CREATE POLICY "Users can delete their own messages" ON chat_messages
FOR DELETE USING (
  auth.uid() = sender_id
);

-- ==============================================
-- ADMIN POLICIES (if needed)
-- ==============================================

-- Policy: Admins can view all conversations (optional)
CREATE POLICY "Admins can view all conversations" ON chat_conversations
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() AND u.user_type = 'admin'
  )
);

-- Policy: Admins can view all messages (optional)
CREATE POLICY "Admins can view all messages" ON chat_messages
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM users u 
    WHERE u.id = auth.uid() AND u.user_type = 'admin'
  )
);

-- ==============================================
-- PERFORMANCE INDEXES
-- ==============================================

-- Indexes for chat_conversations
CREATE INDEX IF NOT EXISTS idx_chat_conversations_customer_runner ON chat_conversations(customer_id, runner_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_errand_id ON chat_conversations(errand_id) WHERE errand_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chat_conversations_transportation_id ON chat_conversations(transportation_booking_id) WHERE transportation_booking_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_chat_conversations_status ON chat_conversations(status);

-- Indexes for chat_messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_is_read ON chat_messages(is_read);

-- ==============================================
-- HELPER FUNCTIONS
-- ==============================================

-- Function to get conversation by errand ID
CREATE OR REPLACE FUNCTION get_errand_conversation(p_errand_id UUID)
RETURNS TABLE (
  id UUID,
  conversation_type TEXT,
  errand_id UUID,
  customer_id UUID,
  runner_id UUID,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cc.id,
    cc.conversation_type,
    cc.errand_id,
    cc.customer_id,
    cc.runner_id,
    cc.status,
    cc.created_at,
    cc.updated_at
  FROM chat_conversations cc
  WHERE cc.conversation_type = 'errand' 
    AND cc.errand_id = p_errand_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get conversation by transportation booking ID
CREATE OR REPLACE FUNCTION get_transportation_conversation(p_booking_id UUID)
RETURNS TABLE (
  id UUID,
  conversation_type TEXT,
  transportation_booking_id UUID,
  customer_id UUID,
  runner_id UUID,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cc.id,
    cc.conversation_type,
    cc.transportation_booking_id,
    cc.customer_id,
    cc.runner_id,
    cc.status,
    cc.created_at,
    cc.updated_at
  FROM chat_conversations cc
  WHERE cc.conversation_type = 'transportation' 
    AND cc.transportation_booking_id = p_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create errand conversation
CREATE OR REPLACE FUNCTION create_errand_conversation(
  p_errand_id UUID,
  p_customer_id UUID,
  p_runner_id UUID
)
RETURNS UUID AS $$
DECLARE
  conversation_id UUID;
BEGIN
  -- Check if conversation already exists
  SELECT id INTO conversation_id
  FROM chat_conversations
  WHERE conversation_type = 'errand' 
    AND errand_id = p_errand_id;
  
  IF conversation_id IS NOT NULL THEN
    RETURN conversation_id;
  END IF;
  
  -- Create new conversation
  INSERT INTO chat_conversations (
    conversation_type,
    errand_id,
    customer_id,
    runner_id,
    status
  ) VALUES (
    'errand',
    p_errand_id,
    p_customer_id,
    p_runner_id,
    'active'
  ) RETURNING id INTO conversation_id;
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create transportation conversation
CREATE OR REPLACE FUNCTION create_transportation_conversation(
  p_booking_id UUID,
  p_customer_id UUID,
  p_runner_id UUID
)
RETURNS UUID AS $$
DECLARE
  conversation_id UUID;
BEGIN
  -- Check if conversation already exists
  SELECT id INTO conversation_id
  FROM chat_conversations
  WHERE conversation_type = 'transportation' 
    AND transportation_booking_id = p_booking_id;
  
  IF conversation_id IS NOT NULL THEN
    RETURN conversation_id;
  END IF;
  
  -- Create new conversation
  INSERT INTO chat_conversations (
    conversation_type,
    transportation_booking_id,
    customer_id,
    runner_id,
    status
  ) VALUES (
    'transportation',
    p_booking_id,
    p_customer_id,
    p_runner_id,
    'active'
  ) RETURNING id INTO conversation_id;
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for helper functions
GRANT EXECUTE ON FUNCTION get_errand_conversation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_transportation_conversation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_errand_conversation(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_transportation_conversation(UUID, UUID, UUID) TO authenticated;

-- ==============================================
-- COMMENTS FOR DOCUMENTATION
-- ==============================================

COMMENT ON TABLE chat_conversations IS 'Chat conversations for both errands and transportation bookings. Use conversation_type to distinguish between them.';
COMMENT ON TABLE chat_messages IS 'Individual messages within chat conversations. Messages are linked to conversations via conversation_id.';

COMMENT ON COLUMN chat_conversations.conversation_type IS 'Type of conversation: errand or transportation';
COMMENT ON COLUMN chat_conversations.errand_id IS 'Reference to errand for errand conversations (nullable for transportation)';
COMMENT ON COLUMN chat_conversations.transportation_booking_id IS 'Reference to transportation_booking for transportation conversations (nullable for errands)';

COMMENT ON COLUMN chat_messages.conversation_id IS 'Reference to the chat conversation this message belongs to';
COMMENT ON COLUMN chat_messages.sender_id IS 'User who sent this message';
COMMENT ON COLUMN chat_messages.message_type IS 'Type of message: text, image, location, or status_update';
COMMENT ON COLUMN chat_messages.is_read IS 'Whether the message has been read by the recipient';
