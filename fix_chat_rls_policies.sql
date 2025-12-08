-- Fix Chat RLS Policies
-- This script fixes the row-level security policies for the chat system

-- Enable RLS on chat tables
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Chat conversations table policies
CREATE POLICY "Users can view their conversations" ON chat_conversations
FOR SELECT USING (
  auth.uid() = customer_id OR auth.uid() = runner_id
);

CREATE POLICY "Users can create conversations" ON chat_conversations
FOR INSERT WITH CHECK (
  auth.uid() = customer_id OR auth.uid() = runner_id
);

CREATE POLICY "Users can update their conversations" ON chat_conversations
FOR UPDATE USING (
  auth.uid() = customer_id OR auth.uid() = runner_id
) WITH CHECK (
  auth.uid() = customer_id OR auth.uid() = runner_id
);

CREATE POLICY "Users can delete their conversations" ON chat_conversations
FOR DELETE USING (
  auth.uid() = customer_id OR auth.uid() = runner_id
);

-- Chat messages table policies
CREATE POLICY "Users can view messages in their conversations" ON chat_messages
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM chat_conversations cc 
    WHERE cc.id = chat_messages.conversation_id 
    AND (auth.uid() = cc.customer_id OR auth.uid() = cc.runner_id)
  )
);

CREATE POLICY "Users can send messages in their conversations" ON chat_messages
FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1 FROM chat_conversations cc 
    WHERE cc.id = chat_messages.conversation_id 
    AND (auth.uid() = cc.customer_id OR auth.uid() = cc.runner_id)
  )
);

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

CREATE POLICY "Users can delete their own messages" ON chat_messages
FOR DELETE USING (
  auth.uid() = sender_id
);
