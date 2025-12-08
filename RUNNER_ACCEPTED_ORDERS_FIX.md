# Fix for Runners Not Seeing Accepted Orders

## Problem Description
Runners are unable to see orders that they have accepted. The issue appears to be related to Row Level Security (RLS) policies in the Supabase database that are too restrictive.

## Root Cause Analysis

### 1. RLS Policy Issue
The current RLS policy for the `errands` table only allows viewing posted errands:
```sql
CREATE POLICY "Anyone can view posted errands" ON errands
    FOR SELECT USING (true);
```

This policy is too restrictive because:
- It only allows viewing errands with `status = 'posted'`
- Runners need to see errands with statuses: `accepted`, `in_progress`, `completed`
- The policy doesn't account for runners needing to view their assigned errands

### 2. Status Flow
The correct errand status flow is:
- `posted` → `accepted` → `in_progress` → `completed`

When a runner accepts an errand, the status changes from `posted` to `accepted`, but the current RLS policy prevents viewing accepted errands.

## Solution

### Step 1: Fix RLS Policies
Run the SQL script `lib/supabase/fix_errand_rls_policies.sql` in your Supabase SQL editor:

```sql
-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Anyone can view posted errands" ON errands;

-- Create a comprehensive policy that allows:
-- 1. Anyone to view posted errands (for discovery)
-- 2. Customers to view their own errands
-- 3. Runners to view errands they've accepted or are working on
CREATE POLICY "Comprehensive errand viewing policy" ON errands
    FOR SELECT USING (
        -- Anyone can view posted errands
        status = 'posted' OR
        -- Customers can view their own errands
        auth.uid() = customer_id OR
        -- Runners can view errands they've accepted, are working on, or completed
        auth.uid() = runner_id
    );
```

### Step 2: Debug Current State
Run the debug script `lib/supabase/debug_runner_errands.sql` to check:
- Current user authentication
- Available runner users
- Existing errands and their statuses
- RLS policies
- Test queries manually

### Step 3: Test with Sample Data
If no accepted errands exist, use `lib/supabase/test_accepted_errand.sql` to create test data.

### Step 4: Verify Flutter App
The Flutter app has been updated with debug logging to help diagnose issues:
- Added debug logging to `getRunnerErrands` function
- Added user profile debugging
- Enhanced error reporting

## Expected Behavior After Fix

1. **Runners can see posted errands** - to accept new work
2. **Runners can see accepted errands** - that they've accepted
3. **Runners can see in-progress errands** - that they're working on
4. **Runners can see completed errands** - that they've finished
5. **Customers can see their own errands** - regardless of status

## Testing Steps

1. **Apply RLS policy fix** in Supabase
2. **Run debug scripts** to verify current state
3. **Test with Flutter app** - check console logs for debug information
4. **Verify errands appear** in runner dashboard with "Accepted" filter
5. **Test status transitions** - accept → start → complete

## Debug Information

The Flutter app now includes comprehensive logging:
- User authentication status
- User profile information
- Database query results
- Error details and types

Check the console output when running the runner dashboard to see exactly what's happening with the database queries.

## Files Modified

- `lib/supabase/fix_errand_rls_policies.sql` - New RLS policy fix
- `lib/supabase/debug_runner_errands.sql` - Debug script
- `lib/supabase/test_accepted_errand.sql` - Test data script
- `lib/supabase/supabase_config.dart` - Enhanced debug logging
- `lib/pages/runner_dashboard_page.dart` - Added profile debugging

## Next Steps

1. Apply the RLS policy fix in Supabase
2. Test the runner dashboard
3. If issues persist, run debug scripts to identify the problem
4. Check console logs for detailed error information
5. Verify that accepted errands now appear in the runner's dashboard
