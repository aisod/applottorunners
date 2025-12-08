# Terms and Conditions Acceptance Implementation

## Overview
This implementation ensures that all users must accept the Terms and Conditions before using the Lotto Runners platform. The acceptance is tracked in the database and only needs to be done once per user.

## Files Created/Modified

### 1. Database Migration
**File:** `add_terms_acceptance_column.sql`
- Adds `terms_accepted` (BOOLEAN) column to users table
- Adds `terms_accepted_at` (TIMESTAMP) column to track when terms were accepted
- Sets default value to `false` for existing users

### 2. Terms Acceptance Dialog Widget
**File:** `lib/widgets/terms_acceptance_dialog.dart`
- Non-dismissible dialog that requires users to accept terms
- Shows appropriate terms summary based on user type (runner vs individual)
- Includes link to view full terms and conditions
- Only allows proceeding after acceptance

### 3. Supabase Config Update
**File:** `lib/supabase/supabase_config.dart`
- Added `acceptTermsAndConditions()` method to mark terms as accepted
- Updates both `terms_accepted` and `terms_accepted_at` fields

### 4. HomePage Update
**File:** `lib/pages/home_page.dart`
- Added `_checkTermsAcceptance()` method to check if terms have been accepted
- Shows terms acceptance dialog automatically on first login
- Updates local profile state after acceptance

## How It Works

1. **On User Login:**
   - HomePage loads user profile
   - Checks if `terms_accepted` is `false` or `null`
   - If not accepted, shows the terms acceptance dialog

2. **Terms Acceptance Dialog:**
   - Cannot be dismissed without accepting
   - Shows summary of key terms based on user type
   - Provides link to view full terms page
   - User must click "I Accept Terms & Conditions" to proceed

3. **After Acceptance:**
   - Updates database with `terms_accepted = true` and timestamp
   - Updates local profile state
   - Dialog closes and user can use the app
   - Never shows again for that user

## Database Setup

Run the SQL migration in your Supabase SQL Editor:

```sql
-- Add Terms and Conditions Acceptance Tracking
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_terms_accepted ON users(terms_accepted);

-- Update existing users to have terms_accepted = false (they need to accept)
UPDATE users 
SET terms_accepted = false 
WHERE terms_accepted IS NULL;
```

## User Experience

- **First Time Users:** Will see the terms acceptance dialog immediately after login
- **Returning Users:** Will not see the dialog again once they've accepted
- **Cannot Skip:** The dialog cannot be dismissed without accepting
- **User Type Specific:** Shows appropriate terms summary based on whether user is a runner or customer

## Testing

1. **Test New User:**
   - Sign up a new user
   - Should see terms acceptance dialog on first login
   - Accept terms and verify dialog doesn't show again

2. **Test Existing User:**
   - After running migration, existing users will have `terms_accepted = false`
   - Next login should show the dialog
   - After accepting, should not show again

3. **Test Different User Types:**
   - Verify runner sees runner-specific terms summary
   - Verify individual/business users see customer-specific terms summary

## Notes

- The dialog is shown using `barrierDismissible: false` to prevent accidental dismissal
- Terms acceptance is tracked per user in the database
- The check happens automatically on HomePage load
- No manual intervention required after initial setup

