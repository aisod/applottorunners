# Debug Runner Acceptance - Step by Step Guide

## What I've Added

I've added comprehensive debugging to the runner acceptance functionality in your Flutter app. The debug output will help us identify the exact error preventing runners from accepting contract and shuttle services.

## Files Modified

1. **`lib/pages/available_errands_page.dart`** - Added debug logging to `_acceptTransportationBooking()`
2. **`lib/pages/runner_dashboard_page.dart`** - Added debug logging to `_acceptTransportationBooking()`
3. **`lib/supabase/supabase_config.dart`** - Added debug logging to `updateTransportationBooking()`

## How to Test and See Debug Output

### Step 1: Run the App
```bash
flutter run
```

### Step 2: Try to Accept a Booking
1. **As a Runner**: Log in as a runner user
2. **Go to Available Jobs**: Navigate to the available errands/transportation page
3. **Find a Transportation Booking**: Look for shuttle or contract services
4. **Click Accept**: Try to accept the booking
5. **Watch the Console**: The debug output will show in your terminal/console

### Step 3: Look for Debug Messages

The debug output will show messages like:
```
🚀 DEBUG: Starting transportation booking acceptance...
📋 DEBUG: Booking data: {...}
👤 DEBUG: Current user ID: abc123
🚌 DEBUG: Service name: Shuttle Service
🚌 DEBUG: Is bus service: false
📝 DEBUG: Update data: {status: accepted, driver_id: abc123, ...}
🔄 DEBUG: Calling updateTransportationBooking...
```

### Step 4: Identify the Error

Look for these specific error indicators:

#### **Constraint Violation** (Most Likely)
```
🚨 DEBUG: CONSTRAINT VIOLATION DETECTED!
🚨 DEBUG: This is likely a status constraint issue
🚨 DEBUG: Check if "accepted" status is allowed in the constraint
```

#### **RLS Policy Violation**
```
🚨 DEBUG: RLS POLICY VIOLATION DETECTED!
🚨 DEBUG: This is likely a Row Level Security policy issue
🚨 DEBUG: Check if the user has permission to update this booking
```

#### **General Exception**
```
💥 DEBUG: Exception caught in _acceptTransportationBooking
💥 DEBUG: Error: [specific error message]
💥 DEBUG: Stack trace: [stack trace]
```

## Expected Debug Flow

### Successful Acceptance:
```
🚀 DEBUG: Starting transportation booking acceptance...
✅ DEBUG: User confirmed acceptance
👤 DEBUG: Current user ID: [user-id]
🚌 DEBUG: Service name: [service-name]
🚌 DEBUG: Is bus service: false
📝 DEBUG: Update data: {status: accepted, driver_id: [user-id], ...}
🔄 DEBUG: Calling updateTransportationBooking...
🔄 DEBUG: updateTransportationBooking called
📊 DEBUG: Current booking status: pending
✅ DEBUG: Is acceptance: true
🔄 DEBUG: Executing update...
✅ DEBUG: Non-cancellation update successful
📊 DEBUG: Update result: true
✅ DEBUG: Booking update successful
```

### Failed Acceptance (Constraint Issue):
```
🚀 DEBUG: Starting transportation booking acceptance...
✅ DEBUG: User confirmed acceptance
📝 DEBUG: Update data: {status: accepted, driver_id: [user-id], ...}
🔄 DEBUG: Calling updateTransportationBooking...
🔄 DEBUG: updateTransportationBooking called
🔄 DEBUG: Executing update...
💥 DEBUG: Exception in updateTransportationBooking
🚨 DEBUG: CONSTRAINT VIOLATION DETECTED!
💥 DEBUG: Error: new row for relation "transportation_bookings" violates check constraint "transportation_bookings_status_check"
```

## Common Issues to Look For

### 1. **Status Constraint Issue**
- **Error**: `violates check constraint "transportation_bookings_status_check"`
- **Cause**: Database constraint doesn't allow `'accepted'` status
- **Solution**: Run the `fix_transportation_acceptance_complete.sql` script

### 2. **RLS Policy Issue**
- **Error**: `row-level security policy` or `permission denied`
- **Cause**: User doesn't have permission to update the booking
- **Solution**: Update RLS policies (included in the fix script)

### 3. **Missing Driver ID Column**
- **Error**: `column "driver_id" does not exist`
- **Cause**: Contract bookings table missing driver_id column
- **Solution**: Add driver_id column (included in the fix script)

### 4. **Runner Limits**
- **Debug**: `Can accept transportation: false`
- **Cause**: Runner has reached the 2-job limit
- **Solution**: Complete existing jobs first

## Next Steps After Debugging

1. **Run the app** and try to accept a booking
2. **Copy the debug output** from your console
3. **Share the specific error message** you see
4. **Apply the appropriate fix** based on the error type

## Quick Fix Commands

If you see a constraint violation, run this in your Supabase SQL editor:
```sql
-- Copy and paste the contents of fix_transportation_acceptance_complete.sql
```

## Debug Output Examples

### Example 1: Constraint Violation
```
💥 DEBUG: Error: PostgrestException(message: new row for relation "transportation_bookings" violates check constraint "transportation_bookings_status_check", code: 23514)
🚨 DEBUG: CONSTRAINT VIOLATION DETECTED!
```

### Example 2: RLS Policy Violation
```
💥 DEBUG: Error: PostgrestException(message: new row violates row-level security policy for table "transportation_bookings", code: 42501)
🚨 DEBUG: RLS POLICY VIOLATION DETECTED!
```

### Example 3: Missing Column
```
💥 DEBUG: Error: PostgrestException(message: column "driver_id" does not exist, code: 42703)
```

The debug output will tell us exactly what's wrong so we can fix it!
