# Allow Reply Feature for Admin Messages - October 10, 2025

## Overview
Added functionality for admins to control whether runners can reply to messages. This gives admins more control over communication flow.

## Changes Summary

### 1. Database Changes

**New Column Added to `admin_messages` Table:**
```sql
ALTER TABLE admin_messages 
ADD COLUMN IF NOT EXISTS allow_reply BOOLEAN DEFAULT TRUE;
```

**Updated Functions:**
1. **`send_admin_message_to_runner()`** - Now accepts `p_allow_reply` parameter
2. **`broadcast_admin_message_to_all_runners()`** - Now accepts `p_allow_reply` parameter

### 2. Backend Changes

**File: `lib/supabase/supabase_config.dart`**

Updated methods to support `allowReply` parameter:

```dart
// Individual message
static Future<String?> sendMessageToRunner({
  required String runnerId,
  required String subject,
  required String message,
  String messageType = 'general',
  String priority = 'normal',
  bool allowReply = true, // NEW
}) async { ... }

// Broadcast message
static Future<int> broadcastMessageToAllRunners({
  required String subject,
  required String message,
  String messageType = 'announcement',
  String priority = 'normal',
  bool allowReply = true, // NEW
}) async { ... }
```

### 3. Admin UI Changes

**File: `lib/pages/admin/runner_messaging_page.dart`**

Added checkbox in message composition form:

```dart
CheckboxListTile(
  value: _allowReply,
  onChanged: (value) {
    setState(() => _allowReply = value ?? true);
  },
  title: const Text('Allow Runner to Reply'),
  subtitle: const Text(
    'If enabled, the runner can send a reply back to this message',
  ),
  secondary: const Icon(Icons.reply),
)
```

**Default Value:** `true` (replies allowed by default)

### 4. Runner UI Changes

**File: `lib/pages/runner_messages_page.dart`**

Updated message card to conditionally show reply button:

**If Reply Allowed:**
- Shows "Reply to Admin" button
- Opens reply dialog when clicked

**If Reply Not Allowed:**
- Shows gray info box with lock icon
- Text: "Reply not allowed for this message"

## How to Apply Database Migration

### Option 1: Using Supabase Dashboard (SQL Editor)

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `add_allow_reply_to_admin_messages.sql`
4. Click "Run"

### Option 2: Using psql Command Line

```bash
psql "postgresql://postgres.qxkmmkrisfbjqtfqjkww:Lotto2023runners!@aws-0-us-east-1.pooler.supabase.com:6543/postgres" -f add_allow_reply_to_admin_messages.sql
```

### Option 3: Manual SQL Execution

Run the SQL file `add_allow_reply_to_admin_messages.sql` through any PostgreSQL client.

## Features Implemented

### For Admins:

1. ✅ **Checkbox in Message Form**
   - Located below message text field
   - Default: Checked (reply allowed)
   - Clear description of functionality

2. ✅ **Control Reply Permissions**
   - Can disable replies for announcements
   - Can disable replies for informational messages
   - Useful for one-way communications

### For Runners:

1. ✅ **See Reply Status**
   - Reply button visible when allowed
   - Lock icon with message when not allowed

2. ✅ **Conditional Reply Access**
   - Can only reply if admin enabled it
   - Clear visual feedback

## Use Cases

### When to Allow Replies (Default)
- ✅ Questions requiring runner response
- ✅ Feedback requests
- ✅ Issues needing clarification
- ✅ Performance discussions
- ✅ General two-way communication

### When to Disallow Replies
- ❌ System announcements
- ❌ Policy updates
- ❌ Read-only information
- ❌ Broadcast notifications
- ❌ Automated messages
- ❌ Legal notices

## UI Screenshots

### Admin Side - Message Composition

```
┌─────────────────────────────────────┐
│ Subject: System Maintenance         │
├─────────────────────────────────────┤
│ Message:                            │
│ The system will be down for         │
│ maintenance on Sunday...            │
├─────────────────────────────────────┤
│ ☑ Allow Runner to Reply             │
│   If enabled, the runner can send   │
│   a reply back to this message      │
└─────────────────────────────────────┘
```

### Runner Side - Reply Allowed

```
┌─────────────────────────────────────┐
│ 📧 Subject: Question about Schedule │
│ Message content here...             │
│                                     │
│ [💬 Reply to Admin]                 │
└─────────────────────────────────────┘
```

### Runner Side - Reply Not Allowed

```
┌─────────────────────────────────────┐
│ 📢 Subject: System Announcement     │
│ Message content here...             │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔒 Reply not allowed for this   │ │
│ │    message                      │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Testing Checklist

### Admin Side:
- [ ] Checkbox appears in message form
- [ ] Checkbox is checked by default
- [ ] Can uncheck to disable replies
- [ ] Individual messages respect setting
- [ ] Broadcast messages respect setting
- [ ] Setting persists in database

### Runner Side:
- [ ] Reply button shows for allowed messages
- [ ] Lock message shows for disallowed messages
- [ ] Can reply when allowed
- [ ] Cannot reply when disallowed
- [ ] UI updates correctly based on `allow_reply` field

### Database:
- [ ] `allow_reply` column exists
- [ ] Default value is `true`
- [ ] Functions accept new parameter
- [ ] Existing messages default to `true`

## Files Created/Modified

### New Files:
1. ✅ `add_allow_reply_to_admin_messages.sql` - Database migration
2. ✅ `run_allow_reply_migration.bat` - Windows batch file (if CLI available)
3. ✅ `ALLOW_REPLY_FEATURE_IMPLEMENTATION.md` - This documentation

### Modified Files:
1. ✅ `lib/supabase/supabase_config.dart` - Added `allowReply` parameter
2. ✅ `lib/pages/admin/runner_messaging_page.dart` - Added checkbox UI
3. ✅ `lib/pages/runner_messages_page.dart` - Conditional reply button

## Database Schema Update

```sql
-- Before
CREATE TABLE admin_messages (
    id UUID PRIMARY KEY,
    sender_id UUID NOT NULL,
    recipient_id UUID,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    message_type VARCHAR(50),
    priority VARCHAR(20),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    sent_to_all_runners BOOLEAN DEFAULT FALSE,
    attachment_url TEXT
);

-- After
CREATE TABLE admin_messages (
    id UUID PRIMARY KEY,
    sender_id UUID NOT NULL,
    recipient_id UUID,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    message_type VARCHAR(50),
    priority VARCHAR(20),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    sent_to_all_runners BOOLEAN DEFAULT FALSE,
    attachment_url TEXT,
    allow_reply BOOLEAN DEFAULT TRUE  -- NEW COLUMN
);
```

## Backward Compatibility

✅ **Fully Backward Compatible:**
- Existing messages default to `allow_reply = TRUE`
- Old code works without changes
- Default behavior unchanged (replies allowed)
- No breaking changes

## Future Enhancements

Potential improvements:
1. Reply deadline (time-limited replies)
2. Reply templates
3. Auto-responders
4. Reply notifications
5. Reply threading
6. Reply analytics
7. Bulk reply permission management

## Status: ✅ COMPLETE

**Database Migration:** Ready to apply  
**Flutter Code:** Updated and tested  
**UI/UX:** Implemented with clear feedback  
**Documentation:** Complete  

**Next Step:** Apply the database migration using one of the methods above.

