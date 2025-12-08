# Order Flow System Implementation

## Overview
This document outlines the implementation of the complete order flow system for the Lotto Runners app, including chat functionality, notifications, and cancel rules.

## Order Flow States

### 1. Pending → Waiting for Runner
- **Status**: `pending`
- **Description**: Errand is posted and waiting for a runner to accept
- **Actions Available**: Runner can click "Begin Work" to accept

### 2. Accepted → Runner Clicks Button → Chat Opens
- **Status**: `accepted`
- **Description**: Runner has accepted the errand
- **Actions Available**: 
  - Runner can click "Start Errand" to begin work
  - Runner can click "Chat" to open communication
  - Runner can click "Cancel Errand" to return to available

### 3. In Progress → Runner Starts Order
- **Status**: `in_progress`
- **Description**: Runner is actively working on the errand
- **Actions Available**:
  - Runner can click "Complete Errand" to finish
  - Runner can click "Chat" to communicate with customer
  - Runner can click "Cancel Errand" to return to available

### 4. Completed → Runner Finishes → Chat Closes
- **Status**: `completed`
- **Description**: Errand has been completed successfully
- **Actions Available**: None (chat automatically closes)

### 5. Cancelled → Either Side Cancels → Goes Back to Available
- **Status**: `cancelled`
- **Description**: Errand has been cancelled by either party
- **Actions Available**: None (chat automatically closes)

## Chat System

### Features
- **Automatic Creation**: Chat conversation is created when runner accepts an errand
- **Real-time Messaging**: Users can send and receive messages
- **Status Updates**: Automatic messages for status changes (started, completed, cancelled)
- **Auto-close**: Chat closes when errand is completed or cancelled

### Implementation
- **Chat Page**: `lib/pages/chat_page.dart`
- **Chat Service**: `lib/services/chat_service.dart`
- **Database Tables**: `chat_conversations` and `chat_messages`

### Chat Flow
1. Runner accepts errand → Chat conversation created
2. Welcome message sent automatically
3. Both parties can send messages
4. Status updates appear as special messages
5. Chat closes automatically on completion/cancellation

## Notifications

### Runner Notifications
- **User cancels order**: Runner gets notified when customer cancels
- **User books transport/errand**: Runner gets notified of new requests

### User Notifications
- **Runner cancels**: Customer gets notified when runner cancels
- **Runner starts**: Customer gets notified when work begins
- **Runner finishes**: Customer gets notified when errand is completed

### Implementation
- **Notification Service**: `lib/services/notification_service.dart`
- **Automatic Triggers**: Notifications sent on status changes
- **Local Notifications**: Uses Flutter Local Notifications plugin

## Cancel Rules

### Runner Cancellation
- **Can cancel**: `accepted` or `in_progress` status
- **Result**: Order goes back to available list
- **Chat**: Automatically closes
- **Notification**: Customer gets notified

### User Cancellation
- **Can cancel**: Any status except `completed`
- **Result**: Order marked as cancelled
- **Chat**: Automatically closes
- **Notification**: Runner gets notified (if assigned)

## Database Schema Updates

### New Tables
```sql
-- Chat conversations table
CREATE TABLE chat_conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    runner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    closed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(errand_id)
);

-- Chat messages table
CREATE TABLE chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES chat_conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'location', 'status_update')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Updated Tables
- **Errands table**: Added `started_at` column and updated status constraints
- **Indexes**: Added performance indexes for chat-related queries

## API Methods

### New Methods in SupabaseConfig
- `acceptErrand()`: Accepts errand and creates chat conversation
- `startErrand()`: Starts errand and sends status update
- `completeErrand()`: Completes errand and closes chat
- `cancelErrand()`: Cancels errand with reason and closes chat
- `getErrandChat()`: Gets chat conversation for an errand
- `getChatMessages()`: Gets messages for a conversation

### Helper Methods
- `_createErrandChat()`: Creates chat conversation
- `_sendStatusUpdateMessage()`: Sends status update messages
- `_closeErrandChat()`: Closes chat conversation
- Various notification helper methods

## UI Updates

### Runner Dashboard
- **Chat Button**: Added to accepted and in-progress errands
- **Cancel Button**: Added to accepted and in-progress errands
- **Status Updates**: Real-time status changes with visual feedback

### Chat Page
- **Modern Design**: Clean, intuitive chat interface
- **Message Types**: Support for text and status update messages
- **Real-time Updates**: Messages appear immediately
- **Responsive Layout**: Works on all screen sizes

## Security & Permissions

### Row Level Security (RLS)
- Users can only access their own conversations
- Runners can only see assigned errands
- Customers can only see their own errands

### Data Validation
- Status transitions are validated
- Cancellation rules are enforced
- Chat access is restricted to involved parties

## Error Handling

### Graceful Degradation
- Chat creation failures don't prevent errand acceptance
- Message sending failures are handled gracefully
- Network issues are handled with user-friendly messages

### User Feedback
- Loading states for all operations
- Success/error messages for user actions
- Confirmation dialogs for destructive actions

## Future Enhancements

### Planned Features
- **Push Notifications**: Real-time push notifications for messages
- **File Sharing**: Support for images and documents in chat
- **Voice Messages**: Audio message support
- **Chat History**: Persistent chat history across app sessions
- **Typing Indicators**: Show when other party is typing

### Performance Optimizations
- **Message Pagination**: Load messages in chunks for large conversations
- **Offline Support**: Queue messages when offline
- **Message Search**: Search through chat history
- **Chat Backup**: Export chat conversations

## Testing

### Test Scenarios
1. **Accept Errand**: Verify chat creation and welcome message
2. **Start Errand**: Verify status update and notification
3. **Send Message**: Verify message delivery and persistence
4. **Complete Errand**: Verify chat closure and final notification
5. **Cancel Errand**: Verify cancellation rules and chat closure
6. **Error Handling**: Verify graceful handling of failures

### Manual Testing
- Test all status transitions
- Verify chat functionality across different devices
- Test notification delivery
- Validate cancel rules enforcement

## Deployment Notes

### Database Migration
- Run the updated `supabase_tables.sql` script
- Ensure all new columns and constraints are applied
- Verify indexes are created for performance

### App Update
- Deploy updated Flutter app
- Test chat functionality in staging environment
- Monitor for any performance issues
- Gather user feedback on new features

## Conclusion

The order flow system provides a complete, user-friendly experience for both runners and customers. The chat system enables real-time communication, while the notification system keeps all parties informed of important updates. The cancel rules ensure fair and consistent handling of cancellations.

The implementation follows best practices for security, performance, and user experience, with comprehensive error handling and graceful degradation. The system is designed to be scalable and maintainable for future enhancements.
