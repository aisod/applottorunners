# Transportation Status Constraint Fix

## Problem Identified

When trying to accept transportation bookings, the following error occurs:

```
Error updating transportation booking: PostgrestException(message: new row for relation "transportation_bookings" violates check constraint "transportation_bookings_status_check", code: 23514, details: , hint: null)
```

## Root Cause

**Conflicting Status Constraints**: There were multiple, inconsistent status constraints on the `transportation_bookings.status` column:

### Constraint 1 (in `transportation_system.sql`):
```sql
CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show'))
```

### Constraint 2 (in `fix_transportation_status_constraint.sql`):
```sql
CHECK (status IN ('pending', 'confirmed', 'in_progress', 'cancelled', 'completed', 'no_show'))
```

**Missing Statuses**: The first constraint was missing `'in_progress'` and `'accepted'`, while the second was missing `'accepted'`.

**Code Expectation**: The application code now uses `'accepted'` when accepting a booking, which should work with the comprehensive constraint.

## Solution Implemented

### 1. Created Comprehensive Status Constraint Fix

**File**: `fix_transportation_status_constraint_complete.sql`

This script:
- **Detects** all existing status constraints
- **Removes** conflicting constraints automatically
- **Creates** a single, comprehensive constraint with ALL needed statuses

```sql
CHECK (status IN (
    'pending',      -- Initial booking status
    'accepted',     -- Driver has accepted the booking

    'in_progress',  -- Driver is en route or picking up
    'completed',    -- Trip completed successfully
    'cancelled',    -- Booking was cancelled
    'no_show'       -- Customer didn't show up
))
```

### 2. Updated RLS Policy for Booking Acceptance

**File**: `fix_transportation_available_viewing.sql`

Enhanced the "Drivers can accept bookings" policy to:
- **Allow initial acceptance** when `driver_id` is being set from `NULL`
- **Support 'confirmed' status** explicitly in the WITH CHECK clause
- **Maintain security** while enabling legitimate booking acceptance

```sql
CREATE POLICY "Drivers can accept bookings" ON transportation_bookings 
FOR UPDATE USING (
    -- Allow if the user is the assigned driver
    auth.uid() = driver_id
    OR
    -- Or if the user is an admin
    is_admin()
    OR
    -- Allow initial acceptance (when driver_id is being set from NULL)
    (OLD.driver_id IS NULL AND driver_id IS NOT NULL)
) WITH CHECK (
    -- Allow updating status when driver is assigned (including 'confirmed')
    (driver_id IS NOT NULL AND OLD.driver_id IS NULL AND status IN ('confirmed', 'accepted', 'in_progress'))
    -- ... other conditions
);
```

## Status Flow for Transportation Bookings

```
pending → confirmed → in_progress → completed
   ↓           ↓
cancelled   cancelled
   ↓
no_show
```

## Files Modified

1. **`fix_transportation_status_constraint_complete.sql`** - Comprehensive status constraint fix
2. **`fix_transportation_available_viewing.sql`** - Enhanced RLS policy for booking acceptance

## Testing Required

1. **Run the status constraint fix** in Supabase to resolve the constraint conflict
2. **Test booking acceptance** to ensure the 'confirmed' status works
3. **Verify all status transitions** work correctly
4. **Check RLS policies** allow legitimate updates while maintaining security

## Why This Fix Works

1. **Eliminates Constraint Conflicts**: Single, comprehensive constraint prevents conflicts
2. **Supports All Statuses**: Includes all statuses needed by the application
3. **Maintains Security**: RLS policies still prevent unauthorized modifications
4. **Enables Workflow**: Drivers can now properly accept and manage bookings

## Common Status Values

- **`pending`**: Booking created, waiting for driver
- **`accepted`**: Driver accepted the booking

- **`in_progress`**: Driver is en route or picking up
- **`completed`**: Trip finished successfully
- **`cancelled`**: Booking was cancelled
- **`no_show`**: Customer didn't show up

This fix ensures that the transportation booking system can handle the complete lifecycle of a booking without constraint violations.
