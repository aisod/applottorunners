# Authentication Setup Instructions

This document provides instructions for setting up and fixing authentication in your Lotto Runners app.

## Quick Fix - Run This First

1. **Go to your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Run the complete authentication fix script:**

```sql
-- Copy and paste the contents of lib/supabase/complete_auth_fix.sql
```

## What the Fix Includes

### 1. Automatic User Profile Creation
- Creates a database trigger that automatically creates user profiles when users sign up
- Handles both new signups and existing users without profiles
- Uses metadata from sign-up to populate user type and other details

### 2. Enhanced Sign-up Form
- Added user type selection (Individual, Business, Runner)
- Added optional phone number field
- Improved validation and error handling
- Better user experience with visual feedback

### 3. Robust Authentication Flow
- Graceful handling of missing user profiles
- Automatic profile creation for existing auth users
- Better error messages and user feedback
- Proper routing based on user types (admin vs regular users)

### 4. Database Improvements
- Fixed Row Level Security (RLS) policies
- Added proper permissions for user profile creation
- Added conflict resolution for profile creation
- Fixed storage policies

### 5. Error Handling
- User-friendly error messages instead of technical errors
- Network error detection and helpful messages
- Success notifications for completed actions
- Loading states with informative messages

## User Types Supported

- **Individual**: Personal errands and tasks
- **Business**: Commercial errands and services  
- **Runner**: Complete errands for others
- **Admin**: Platform management (requires manual database update)

## Testing the Fix

1. **Test Sign-up:**
   - Try creating a new account with each user type
   - Verify phone number validation works
   - Check that user profiles are created correctly

2. **Test Sign-in:**
   - Sign in with existing accounts
   - Verify proper routing to correct dashboard
   - Check admin access works

3. **Test Error Handling:**
   - Try invalid credentials
   - Test network disconnection scenarios
   - Verify error messages are user-friendly

## Admin User Creation

To create an admin user, run this SQL in your Supabase dashboard:

```sql
-- Update an existing user to admin
UPDATE users SET user_type = 'admin', is_verified = true 
WHERE email = 'your-admin-email@example.com';
```

Or use the provided `create_admin_user.sql` script with your email.

## Troubleshooting

### Profile Creation Issues
If profiles aren't being created automatically:
1. Check that the trigger exists: `SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';`
2. Verify RLS policies allow profile creation
3. Run the complete fix script again

### Authentication Errors
- Clear browser cache and try again
- Check Supabase project status
- Verify API keys are correct
- Check network connectivity

### Missing Admin Access
- Verify user_type is set to 'admin' in database
- Check that user is verified (is_verified = true)
- Restart the app after database changes

## Next Steps

After applying these fixes:
1. Test all authentication flows thoroughly
2. Verify admin dashboard access works
3. Check that user type routing is correct
4. Monitor error logs for any remaining issues

The authentication system should now work perfectly with proper user profile creation, error handling, and role-based access control.