# Transportation Bookings Viewing Fix

## Problem Identified

Transportation bookings were not being retrieved for runners to view available bookings, while errands were working fine. The issue was identified by comparing how the two systems handle data retrieval.

## Root Cause

**Missing RLS Policy**: The `transportation_bookings` table was missing a crucial Row Level Security (RLS) policy that allows runners to view available (unassigned) transportation bookings.

### Comparison with Errands

**Errands (Working):**
```sql
CREATE POLICY "Anyone can view posted errands" ON errands FOR SELECT USING (true);
```

**Transportation Bookings (Broken):**
- Only had policies for users viewing their own bookings
- Only had policies for drivers viewing assigned bookings  
- **Missing policy for viewing available/unassigned bookings**

## Solution Implemented

### 1. Added Missing RLS Policies

Created `fix_transportation_available_viewing.sql` with two policies:

**Policy 1: Runners can view available bookings**
```sql
CREATE POLICY "Runners can view available bookings" ON transportation_bookings 
FOR SELECT USING (
    -- Allow viewing if the booking is pending and has no driver assigned
    (status = 'pending' AND driver_id IS NULL)
    OR
    -- Or if the user is the customer who made the booking
    auth.uid() = user_id
    OR
    -- Or if the user is the assigned driver
    auth.uid() = driver_id
    OR
    -- Or if the user is an admin
    is_admin()
);
```

**Policy 2: Drivers can accept bookings**
```sql
CREATE POLICY "Drivers can accept bookings" ON transportation_bookings 
FOR UPDATE USING (
    -- Allow if the user is the assigned driver
    auth.uid() = driver_id
    OR
    -- Or if the user is an admin
    is_admin()
) WITH CHECK (
    -- Ensure only specific fields can be updated when accepting
    (
        -- Allow updating driver_id when accepting a booking
        (driver_id IS NOT NULL AND OLD.driver_id IS NULL)
        OR
        -- Allow updating status when driver is assigned
        (driver_id IS NOT NULL AND OLD.driver_id IS NULL AND status IN ('accepted', 'in_progress'))
        OR
        -- Allow updating other fields if already assigned to this driver
        (OLD.driver_id = auth.uid())
        OR
        -- Allow admin updates
        is_admin()
    )
);
```

### 2. Improved Data Retrieval Method

Replaced the complex `getOtherUsersBookings()` method with a simpler, more targeted `getAvailableTransportationBookings()` method:

```dart
static Future<List<Map<String, dynamic>>> getAvailableTransportationBookings() async {
  // Query for pending bookings with no driver assigned
  final response = await client
      .from('transportation_bookings')
      .select('''
        *,
        user:users!transportation_bookings_user_id_fkey(full_name, email, phone)
      ''')
      .eq('status', 'pending')
      .filter('driver_id', 'is', null)
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
}
```

### 3. Updated UI Components

- Updated `available_errands_page.dart` to use the new method
- Updated `runner_dashboard_page.dart` to use the new method
- Simplified the logic by removing manual filtering
- Removed test-related UI elements and methods

### 4. Cleaned Up Test Code

- Removed `createTestTransportationBooking()` method
- Removed `testTransportationBookingsTable()` method
- Removed "Test Data" button from UI
- Added SQL to remove any test fields from database

## Key Differences from Errands

| Aspect | Errands | Transportation Bookings |
|--------|---------|------------------------|
| **RLS Policy** | `Anyone can view posted errands` | `Runners can view available bookings` |
| **Query Method** | Simple `getAvailableErrands()` | Simple `getAvailableTransportationBookings()` |
| **Data Structure** | Direct query with status filter | Direct query with status + driver filter |
| **User Info** | Built-in join | Built-in join with foreign key |

## Files Modified

1. **`lib/supabase/fix_transportation_available_viewing.sql`** - New RLS policy
2. **`lib/supabase/supabase_config.dart`** - Added new method and cleaned up old method
3. **`lib/pages/available_errands_page.dart`** - Updated to use new method
4. **`lib/pages/runner_dashboard_page.dart`** - Updated to use new method

## Testing Required

1. Run the SQL fix in Supabase to add the missing RLS policies
2. Test that runners can now see available transportation bookings
3. Verify that the existing functionality (users viewing their own bookings) still works
4. Test that drivers can still view their assigned bookings
5. Test that drivers can accept transportation bookings
6. Verify that test fields and methods have been removed

## Why This Fix Works

The fix addresses the fundamental issue: **RLS policies were too restrictive**. By adding a policy that allows viewing of available bookings (similar to how errands work), runners can now see transportation requests they can accept.

The new method also simplifies the data retrieval by:
- Using a single, targeted query instead of complex manual joins
- Leveraging Supabase's built-in foreign key relationships
- Following the same pattern as the working errands system
