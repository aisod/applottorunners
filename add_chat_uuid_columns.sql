-- Add UUID columns for Bus and Contract bookings to chat_conversations table
-- This fixes the chat system to support all booking types

-- 1. Add bus_service_booking_id column for bus service conversations
ALTER TABLE chat_conversations 
ADD COLUMN bus_service_booking_id UUID REFERENCES bus_service_bookings(id) ON DELETE CASCADE;

-- 2. Add contract_booking_id column for contract conversations
ALTER TABLE chat_conversations 
ADD COLUMN contract_booking_id UUID REFERENCES contract_bookings(id) ON DELETE CASCADE;

-- 3. Update conversation_type enum to include 'bus' and 'contract'
ALTER TABLE chat_conversations 
DROP CONSTRAINT IF EXISTS chat_conversations_conversation_type_check;

ALTER TABLE chat_conversations 
ADD CONSTRAINT chat_conversations_conversation_type_check 
CHECK (conversation_type IN ('errand', 'transportation', 'bus', 'contract'));

-- 4. Update the constraint to ensure proper reference is set based on conversation type
ALTER TABLE chat_conversations 
DROP CONSTRAINT IF EXISTS check_conversation_reference;

ALTER TABLE chat_conversations 
ADD CONSTRAINT check_conversation_reference 
CHECK (
  (conversation_type = 'errand' AND errand_id IS NOT NULL AND transportation_booking_id IS NULL AND bus_service_booking_id IS NULL AND contract_booking_id IS NULL) OR
  (conversation_type = 'transportation' AND transportation_booking_id IS NOT NULL AND errand_id IS NULL AND bus_service_booking_id IS NULL AND contract_booking_id IS NULL) OR
  (conversation_type = 'bus' AND bus_service_booking_id IS NOT NULL AND errand_id IS NULL AND transportation_booking_id IS NULL AND contract_booking_id IS NULL) OR
  (conversation_type = 'contract' AND contract_booking_id IS NOT NULL AND errand_id IS NULL AND transportation_booking_id IS NULL AND bus_service_booking_id IS NULL)
);

-- 5. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_conversations_bus_booking ON chat_conversations(conversation_type, bus_service_booking_id) WHERE conversation_type = 'bus';
CREATE INDEX IF NOT EXISTS idx_chat_conversations_contract_booking ON chat_conversations(conversation_type, contract_booking_id) WHERE conversation_type = 'contract';

-- 6. Update unique constraints to allow all conversation types
DROP INDEX IF EXISTS chat_conversations_errand_unique;
DROP INDEX IF EXISTS chat_conversations_transportation_unique;

CREATE UNIQUE INDEX chat_conversations_errand_unique ON chat_conversations(errand_id) WHERE conversation_type = 'errand';
CREATE UNIQUE INDEX chat_conversations_transportation_unique ON chat_conversations(transportation_booking_id) WHERE conversation_type = 'transportation';
CREATE UNIQUE INDEX chat_conversations_bus_unique ON chat_conversations(bus_service_booking_id) WHERE conversation_type = 'bus';
CREATE UNIQUE INDEX chat_conversations_contract_unique ON chat_conversations(contract_booking_id) WHERE conversation_type = 'contract';

-- 7. Add helper functions for bus and contract conversations

-- Function to get bus conversation by booking ID
CREATE OR REPLACE FUNCTION get_bus_conversation_by_booking(booking_id UUID)
RETURNS TABLE (
  id UUID,
  conversation_type TEXT,
  bus_service_booking_id UUID,
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
    cc.bus_service_booking_id,
    cc.customer_id,
    cc.runner_id,
    cc.status,
    cc.created_at,
    cc.updated_at
  FROM chat_conversations cc
  WHERE cc.conversation_type = 'bus' 
    AND cc.bus_service_booking_id = booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get contract conversation by booking ID
CREATE OR REPLACE FUNCTION get_contract_conversation_by_booking(booking_id UUID)
RETURNS TABLE (
  id UUID,
  conversation_type TEXT,
  contract_booking_id UUID,
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
    cc.contract_booking_id,
    cc.customer_id,
    cc.runner_id,
    cc.status,
    cc.created_at,
    cc.updated_at
  FROM chat_conversations cc
  WHERE cc.conversation_type = 'contract' 
    AND cc.contract_booking_id = booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create bus conversation
CREATE OR REPLACE FUNCTION create_bus_conversation(
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
  WHERE conversation_type = 'bus' 
    AND bus_service_booking_id = p_booking_id;
  
  IF conversation_id IS NOT NULL THEN
    RETURN conversation_id;
  END IF;
  
  -- Create new conversation
  INSERT INTO chat_conversations (
    conversation_type,
    bus_service_booking_id,
    customer_id,
    runner_id,
    status
  ) VALUES (
    'bus',
    p_booking_id,
    p_customer_id,
    p_runner_id,
    'active'
  ) RETURNING id INTO conversation_id;
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create contract conversation
CREATE OR REPLACE FUNCTION create_contract_conversation(
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
  WHERE conversation_type = 'contract' 
    AND contract_booking_id = p_booking_id;
  
  IF conversation_id IS NOT NULL THEN
    RETURN conversation_id;
  END IF;
  
  -- Create new conversation
  INSERT INTO chat_conversations (
    conversation_type,
    contract_booking_id,
    customer_id,
    runner_id,
    status
  ) VALUES (
    'contract',
    p_booking_id,
    p_customer_id,
    p_runner_id,
    'active'
  ) RETURNING id INTO conversation_id;
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Grant permissions for helper functions
GRANT EXECUTE ON FUNCTION get_bus_conversation_by_booking(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_contract_conversation_by_booking(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_bus_conversation(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_contract_conversation(UUID, UUID, UUID) TO authenticated;

-- 9. Add comments for documentation
COMMENT ON COLUMN chat_conversations.bus_service_booking_id IS 'Reference to bus_service_booking for bus conversations (nullable for other types)';
COMMENT ON COLUMN chat_conversations.contract_booking_id IS 'Reference to contract_booking for contract conversations (nullable for other types)';
