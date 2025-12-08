-- Fix Chat System for Transportation Support
-- This migration updates the chat_conversations table to support both errands and transportation bookings

-- 1. Add conversation_type column to chat_conversations
ALTER TABLE chat_conversations 
ADD COLUMN conversation_type TEXT NOT NULL DEFAULT 'errand' 
CHECK (conversation_type IN ('errand', 'transportation'));

-- 2. Add transportation_booking_id column for transportation conversations
ALTER TABLE chat_conversations 
ADD COLUMN transportation_booking_id UUID REFERENCES transportation_bookings(id) ON DELETE CASCADE;

-- 3. Make errand_id nullable since transportation conversations won't have it
ALTER TABLE chat_conversations 
ALTER COLUMN errand_id DROP NOT NULL;

-- 4. Add constraint to ensure either errand_id or transportation_booking_id is set
ALTER TABLE chat_conversations 
ADD CONSTRAINT check_conversation_reference 
CHECK (
  (conversation_type = 'errand' AND errand_id IS NOT NULL AND transportation_booking_id IS NULL) OR
  (conversation_type = 'transportation' AND transportation_booking_id IS NOT NULL AND errand_id IS NULL)
);

-- 5. Update existing conversations to have conversation_type = 'errand'
UPDATE chat_conversations 
SET conversation_type = 'errand' 
WHERE conversation_type IS NULL;

-- 6. Add indexes for performance
CREATE INDEX idx_chat_conversations_type_errand ON chat_conversations(conversation_type, errand_id) WHERE conversation_type = 'errand';
CREATE INDEX idx_chat_conversations_type_transportation ON chat_conversations(conversation_type, transportation_booking_id) WHERE conversation_type = 'transportation';
CREATE INDEX idx_chat_conversations_customer ON chat_conversations(customer_id, conversation_type);
CREATE INDEX idx_chat_conversations_runner ON chat_conversations(runner_id, conversation_type);

-- 7. Add RLS policies for transportation conversations
CREATE POLICY "Users can view their transportation conversations" ON chat_conversations
FOR SELECT USING (
  conversation_type = 'transportation' AND 
  (auth.uid() = customer_id OR auth.uid() = runner_id)
);

CREATE POLICY "Users can insert transportation conversations" ON chat_conversations
FOR INSERT WITH CHECK (
  conversation_type = 'transportation' AND 
  (auth.uid() = customer_id OR auth.uid() = runner_id)
);

CREATE POLICY "Users can update their transportation conversations" ON chat_conversations
FOR UPDATE USING (
  conversation_type = 'transportation' AND 
  (auth.uid() = customer_id OR auth.uid() = runner_id)
);

-- 8. Add function to get transportation conversation by booking
CREATE OR REPLACE FUNCTION get_transportation_conversation_by_booking(booking_id UUID)
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
    AND cc.transportation_booking_id = booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Add function to create transportation conversation
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

-- 10. Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_transportation_conversation_by_booking(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_transportation_conversation(UUID, UUID, UUID) TO authenticated;

-- 11. Update existing unique constraint to allow both types
DROP INDEX IF EXISTS chat_conversations_errand_id_key;
CREATE UNIQUE INDEX chat_conversations_errand_unique ON chat_conversations(errand_id) WHERE conversation_type = 'errand';
CREATE UNIQUE INDEX chat_conversations_transportation_unique ON chat_conversations(transportation_booking_id) WHERE conversation_type = 'transportation';

-- 12. Add comment to document the changes
COMMENT ON TABLE chat_conversations IS 'Chat conversations for both errands and transportation bookings. Use conversation_type to distinguish between them.';
COMMENT ON COLUMN chat_conversations.conversation_type IS 'Type of conversation: errand or transportation';
COMMENT ON COLUMN chat_conversations.transportation_booking_id IS 'Reference to transportation_booking for transportation conversations';
COMMENT ON COLUMN chat_conversations.errand_id IS 'Reference to errand for errand conversations (nullable for transportation)';
