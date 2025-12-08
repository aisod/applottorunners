# Admin Messages Not Showing - Troubleshooting Guide

## Current Status
- ✅ Layout rendering error fixed
- ✅ Page loads without crashes
- ✅ 1 message exists in database
- ❓ Messages may not be visible due to RLS policies

## Debug Output Added

When you open the admin messaging page, check the console for these messages:

```
📨 Fetching admin messages...
📨 Current user: <user-id>
✅ Got X admin messages
📨 Loaded X runners
📨 Loaded X admin messages
```

## Possible Issues & Solutions

### Issue 1: RLS Policy Blocking Admin Access

**Symptoms:** Console shows "Got 0 admin messages" even though database has messages

**Solution:** The RLS policy needs the current user to be marked as admin in the database.

Check if your user is an admin:
```sql
SELECT id, email, user_type, is_verified 
FROM users 
WHERE email = 'your-admin-email@example.com';
```

If `user_type` is NOT 'admin', update it:
```sql
UPDATE users 
SET user_type = 'admin' 
WHERE email = 'your-admin-email@example.com';
```

### Issue 2: is_admin() Function Not Working

**Test the function:**
```sql
-- Run this while logged in as admin in the app
SELECT is_admin() as am_i_admin;
```

Should return `true`. If it returns `false`, the function needs fixing.

### Issue 3: Messages Sent By Different Admin

The current implementation shows ALL messages (not just sent by current admin).

Policy: `"Admins can view all messages"` allows ANY admin to see ALL messages.

This is correct behavior for admin oversight.

### Issue 4: Foreign Key References Failing

The query joins with users table twice:
```sql
sender:users!admin_messages_sender_id_fkey(full_name, email),
recipient:users!admin_messages_recipient_id_fkey(full_name, email)
```

If foreign keys don't exist or reference missing users, this fails.

**Check foreign keys:**
```sql
SELECT 
  conname AS constraint_name,
  conrelid::regclass AS table_name,
  confrelid::regclass AS referenced_table
FROM pg_constraint
WHERE conrelid = 'admin_messages'::regclass
AND contype = 'f';
```

## Quick Test

Run this query as the admin user to see if RLS allows access:

```sql
-- This simulates what the app does
SELECT 
  id,
  subject,
  message,
  sent_to_all_runners,
  created_at
FROM admin_messages
ORDER BY created_at DESC;
```

If you get results → RLS works, problem is in the app  
If you get 0 results → RLS is blocking, need to fix policies  
If you get an error → Check the error message

## Check Console Output

After opening the admin messaging page:

**If you see:**
- `❌ Error getting admin messages: <error>` → There's a query error
- `✅ Got 0 admin messages` (but DB has messages) → RLS is blocking
- `✅ Got 1 admin messages` → Data is loading, check if UI renders it

**Expected console output (working):**
```
📨 Fetching admin messages...
📨 Current user: bc904f7a-d912-4128-84c6-6e7fdd85d04d
✅ Got 1 admin messages
📨 Loaded 15 runners
📨 Loaded 1 admin messages
📨 First message: {id: be0396c2-..., subject: send my, ...}
```

## Verify Admin Status

Most common issue: **User is not marked as admin in database**

```sql
-- List all users with their types
SELECT id, full_name, email, user_type 
FROM users 
ORDER BY user_type, email;

-- Set specific user as admin
UPDATE users 
SET user_type = 'admin' 
WHERE email = 'admin@example.com';

-- Verify
SELECT is_admin() as check;  -- Should return true when logged in as that user
```

## Test the is_admin() Function

```sql
-- Check function definition
SELECT pg_get_functiondef('is_admin'::regproc);

-- Test with specific user
SELECT 
  u.id,
  u.email,
  u.user_type,
  (u.user_type = 'admin') as should_be_admin
FROM users u
WHERE u.email = 'your-email@example.com';
```

## If Messages Still Don't Show

1. **Open browser developer tools** (F12)
2. **Go to Console tab**
3. **Navigate to Admin → Messenger tab**
4. **Copy ALL console output** and share it

The debug logs will show exactly where the problem is.

## Quick Fix Commands

If RLS is blocking (most likely issue):

```sql
-- Ensure your user is admin
UPDATE users 
SET user_type = 'admin' 
WHERE id = (SELECT auth.uid());

-- Test immediately
SELECT is_admin();  -- Should return true

-- Try querying messages
SELECT COUNT(*) FROM admin_messages;  -- Should show 1
```

## Summary

The most likely issue is that your user account isn't marked as `user_type = 'admin'` in the database, so the `is_admin()` function returns false, and the RLS policy blocks access.

**Fix:** Update your user's `user_type` to 'admin' in the database.

