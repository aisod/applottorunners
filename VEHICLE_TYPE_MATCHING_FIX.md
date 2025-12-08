# Vehicle Type Matching Fix

## Problem Identified

The notification system was failing because of a database schema mismatch:

1. **Column Name Mismatch**: The code was trying to use `vehicle_type_id` in the `runner_applications` table, but the actual column name is `vehicle_type` (text-based)
2. **Data Type Mismatch**: The system was trying to match UUID vehicle type IDs with text-based vehicle type names

## Error Messages

```
Error notifying runners: PostgrestException(message: column runner_applications.vehicle_type_id does not exist, code: 42703, details: , hint: Perhaps you meant to reference the column "runner_applications.vehicle_type".)
```

## Solution Implemented

### 1. Updated Notification Logic (`lib/supabase/supabase_config.dart`)

**Before:**
```dart
// Get all runners with matching vehicle type
final runnersResponse = await client
    .from('runner_applications')
    .select('user_id')
    .eq('vehicle_type_id', vehicleTypeId)  // ❌ Wrong column name
    .eq('verification_status', 'approved');
```

**After:**
```dart
// Get all runners with matching vehicle type
final runnersResponse = await client
    .from('runner_applications')
    .select('user_id')
    .eq('vehicle_type', vehicleTypeName)  // ✅ Correct column name
    .eq('verification_status', 'approved');
```

### 2. Updated Vehicle Type Retrieval

**Before:**
```dart
static Future<String?> getRunnerVehicleType(String runnerId) async {
  final response = await client
      .from('runner_applications')
      .select('vehicle_type_id')  // ❌ Wrong column name
      .eq('user_id', runnerId)
      .eq('verification_status', 'approved')
      .single();
  
  return response['vehicle_type_id'] as String?;  // ❌ Wrong column name
}
```

**After:**
```dart
static Future<String?> getRunnerVehicleType(String runnerId) async {
  final response = await client
      .from('runner_applications')
      .select('vehicle_type')  // ✅ Correct column name
      .eq('user_id', runnerId)
      .eq('verification_status', 'approved')
      .single();
  
  return response['vehicle_type'] as String?;  // ✅ Correct column name
}
```

### 3. Updated Frontend Filtering

**Runner Dashboard (`lib/pages/runner_dashboard_page.dart`):**

**Before:**
```dart
final pendingBookings = availableBookings
    .where((booking) =>
        booking['status'] == 'pending' &&
        booking['driver_id'] == null &&
        booking['vehicle_type_id'] == runnerVehicleType)  // ❌ UUID comparison
    .toList();
```

**After:**
```dart
final pendingBookings = availableBookings
    .where((booking) {
        if (booking['status'] != 'pending' || booking['driver_id'] != null) {
            return false;
        }
        
        // Get the vehicle type name from the booking
        final bookingVehicleType = booking['vehicle_type']?['name'] ?? '';
        return bookingVehicleType == runnerVehicleType;  // ✅ Text comparison
    })
    .toList();
```

**Available Errands Page (`lib/pages/available_errands_page.dart`):**

Added similar text-based filtering:
```dart
final filteredBookings = availableBookings.where((booking) {
  if (runnerVehicleType == null) return true; // Show all if no vehicle type
  
  final bookingVehicleType = booking['vehicle_type']?['name'] ?? '';
  return bookingVehicleType == runnerVehicleType;
}).toList();
```

### 4. Simplified Backend Query

**Before:**
```dart
// Filter by vehicle type if specified
if (vehicleTypeId != null) {
  query = query.eq('vehicle_type_id', vehicleTypeId);
}
```

**After:**
```dart
// Note: Vehicle type filtering is now done in the frontend for text-based matching
```

## Database Schema Understanding

### Runner Applications Table
```sql
-- The runner_applications table uses text-based vehicle types
CREATE TABLE runner_applications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  vehicle_type TEXT,  -- ✅ Text-based (e.g., 'Sedan', 'SUV', 'Motorcycle')
  verification_status TEXT,
  -- ... other columns
);
```

### Transportation Bookings Table
```sql
-- The transportation_bookings table references vehicle_types table
CREATE TABLE transportation_bookings (
  id UUID PRIMARY KEY,
  vehicle_type_id UUID REFERENCES vehicle_types(id),  -- ✅ UUID reference
  -- ... other columns
);
```

### Vehicle Types Table
```sql
-- The vehicle_types table contains the mapping
CREATE TABLE vehicle_types (
  id UUID PRIMARY KEY,
  name TEXT,  -- ✅ Text-based (e.g., 'Sedan', 'SUV', 'Motorcycle')
  -- ... other columns
);
```

## How the Fix Works

1. **Notification Creation**: When a transportation booking is created, the system:
   - Gets the vehicle type name from the `vehicle_types` table
   - Finds all runners with that same vehicle type name in `runner_applications`
   - Sends notifications to those runners

2. **Frontend Filtering**: When runners view available bookings:
   - Gets the runner's vehicle type name from `runner_applications`
   - Filters transportation bookings to show only those with matching vehicle type names
   - Uses text-based comparison instead of UUID comparison

## Benefits

1. **Correct Data Matching**: Now properly matches vehicle types between runners and bookings
2. **Working Notifications**: Runners receive notifications for bookings matching their vehicle type
3. **Accurate Filtering**: Runners only see transportation bookings they can actually accept
4. **Consistent Logic**: All vehicle type matching now uses the same text-based approach

## Testing

After implementing these fixes:

1. **Create a transportation booking** as a customer
2. **Check runner dashboard** - should show notification badge if runner has matching vehicle type
3. **Verify notifications** - runners should receive notifications for matching vehicle types
4. **Test filtering** - runners should only see bookings for their vehicle type

## Files Modified

- `lib/supabase/supabase_config.dart` - Updated notification and vehicle type retrieval logic
- `lib/pages/runner_dashboard_page.dart` - Updated frontend filtering
- `lib/pages/available_errands_page.dart` - Added vehicle type filtering
- `VEHICLE_TYPE_MATCHING_FIX.md` - This documentation

The vehicle type matching system is now working correctly with text-based comparisons instead of UUID-based comparisons!
