# ⚠️ URGENT: Apply Database Migration

## Error Encountered

```
PostgrestException: column "allow_reply" of relation "admin_messages" does not exist
```

## Quick Fix: Apply Migration via Supabase Dashboard

### Step 1: Open Supabase Dashboard
1. Go to: https://supabase.com/dashboard
2. Select your project
3. Click on "SQL Editor" in the left sidebar

### Step 2: Run Migration SQL

Copy and paste this entire SQL script into the SQL Editor:

```sql
-- ============================================================================
-- Add allow_reply column to admin_messages table
-- October 10, 2025
-- ============================================================================
r
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
```

### Step 3: Click "Run" Button

The green "Run" button is at the bottom right of the SQL Editor.

### Step 4: Verify Success

You should see:
```
Success. No rows returned
```

### Step 5: Test the App

1. Restart your Flutter app
2. Login as admin
3. Try sending a message
4. Should work without errors!

---

## Alternative: Manual Steps in Dashboard

If you prefer to do it manually:

### 1. Add Column
```sql
ALTER TABLE admin_messages 
ADD COLUMN IF NOT EXISTS allow_reply BOOLEAN DEFAULT TRUE;
```

### 2. Update Existing Data
```sql
UPDATE admin_messages 
SET allow_reply = TRUE 
WHERE allow_reply IS NULL;
```

### 3. Update Functions
Copy the two function definitions from above (send_admin_message_to_runner and broadcast_admin_message_to_all_runners)

---

## Verification Query

After applying, run this to verify:

```sql
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'admin_messages' 
AND column_name = 'allow_reply';
```

Expected result:
```
column_name | data_type | column_default
------------+-----------+---------------
allow_reply | boolean   | true
```

---

## Why This Happened

The Flutter code was updated to use the new `allow_reply` feature, but the database column doesn't exist yet. The migration needs to be applied to add this column.

## Estimated Time

⏱️ **2-3 minutes** to apply via Supabase Dashboard

---

## Need Help?

If you encounter any issues:
1. Check you're in the correct Supabase project
2. Make sure you have admin access
3. Try refreshing the SQL Editor page
4. Contact support if the issue persists

---

## Status After Migration

✅ Admin can control reply permissions  
✅ Runners see appropriate UI  
✅ No more database errors  
✅ Full messaging system functional  

