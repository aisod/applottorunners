# Chat System Migration for Transportation Support

## Overview
This migration updates the chat system to support both errands and transportation bookings. The current chat system only supports errands, but we need to add support for transportation conversations.

## What This Migration Does

### 1. Database Schema Changes
- Adds `conversation_type` column to distinguish between 'errand' and 'transportation' conversations
- Adds `transportation_booking_id` column for transportation conversations
- Makes `errand_id` nullable (since transportation conversations won't have it)
- Adds proper constraints and indexes for performance

### 2. New Functions
- `get_transportation_conversation_by_booking(booking_id)` - Retrieves transportation conversations
- `create_transportation_conversation(booking_id, customer_id, runner_id)` - Creates new transportation conversations

### 3. Security Updates
- Adds RLS policies for transportation conversations
- Ensures users can only access their own conversations

## How to Run the Migration

### Option 1: Supabase Dashboard (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of `fix_chat_system_for_transportation.sql`
4. Click "Run" to execute the migration

### Option 2: Supabase CLI
```bash
# If you have Supabase CLI installed
supabase db push --file=fix_chat_system_for_transportation.sql
```

### Option 3: Direct Database Connection
If you have direct database access, you can run the SQL commands directly in your database client.

## Migration Steps

The migration will:
1. ✅ Add new columns to `chat_conversations` table
2. ✅ Update existing data to set `conversation_type = 'errand'`
3. ✅ Create new indexes for performance
4. ✅ Add RLS policies for security
5. ✅ Create helper functions for transportation conversations
6. ✅ Update constraints and unique indexes

## Verification

After running the migration, you can verify it worked by:

1. **Check the new columns exist:**
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'chat_conversations' 
ORDER BY ordinal_position;
```

2. **Check the new functions exist:**
```sql
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name LIKE '%transportation%';
```

3. **Test creating a transportation conversation:**
```sql
SELECT create_transportation_conversation(
  'your-booking-id-here',
  'your-customer-id-here', 
  'your-runner-id-here'
);
```

## Rollback (If Needed)

If you need to rollback this migration:

```sql
-- Remove the new columns
ALTER TABLE chat_conversations DROP COLUMN IF EXISTS conversation_type;
ALTER TABLE chat_conversations DROP COLUMN IF EXISTS transportation_booking_id;

-- Make errand_id NOT NULL again
ALTER TABLE chat_conversations ALTER COLUMN errand_id SET NOT NULL;

-- Drop the new functions
DROP FUNCTION IF EXISTS get_transportation_conversation_by_booking(UUID);
DROP FUNCTION IF EXISTS create_transportation_conversation(UUID, UUID, UUID);

-- Drop the new indexes
DROP INDEX IF EXISTS idx_chat_conversations_type_errand;
DROP INDEX IF EXISTS idx_chat_conversations_type_transportation;
DROP INDEX IF EXISTS idx_chat_conversations_customer;
DROP INDEX IF EXISTS idx_chat_conversations_runner;

-- Drop the new policies
DROP POLICY IF EXISTS "Users can view their transportation conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can insert transportation conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can update their transportation conversations" ON chat_conversations;
```

## After Migration

Once the migration is complete:
1. The chat functionality should work for both errands and transportation
2. Users can create and access transportation conversations
3. The existing errand chat functionality remains unchanged
4. All new transportation bookings will have proper chat support

## Troubleshooting

### Common Issues:

1. **"column does not exist" errors**: Make sure you ran the migration on the correct database
2. **Permission errors**: Ensure your database user has ALTER TABLE permissions
3. **Constraint violations**: The migration includes data validation - check for any existing invalid data

### Getting Help:
If you encounter issues:
1. Check the Supabase logs for detailed error messages
2. Verify the migration ran completely
3. Check that all new columns and functions were created
4. Ensure RLS policies are properly applied

## Next Steps

After successful migration:
1. Test the chat functionality with transportation bookings
2. Verify that both customer and driver sides can access conversations
3. Test message sending and receiving
4. Monitor performance with the new indexes
