# Runner Location Display Fix

## Problem
Runner cards were not displaying the correct location information when users requested services. The issue was that different forms use different location field names in the database, but the runner cards were only checking for `location_address`.

## Root Cause Analysis

Each service form stores location data differently:

### 1. **Shopping Form** (category: `shopping`)
- **Stores:**
  - `location_address` = Store names/locations (e.g., "Shoprite, Checkers")
  - `delivery_address` = Customer's delivery address
- **Issue:** Runner cards showed store names instead of delivery location

### 2. **Delivery Form** (category: `delivery`)
- **Stores:**
  - `location_address` = Pickup location
  - `pickup_address` = Pickup location (duplicate)
  - `delivery_address` = Delivery destination
- **Issue:** Runner cards only showed pickup, not the full route

### 3. **License Discs Form** (category: `license_discs`)
- **Stores:**
  - `location_address` = Pickup OR dropoff (depending on service option)
  - `pickup_address` = Where to collect documents
  - `dropoff_address` = Where to deliver processed disc
- **Issue:** May not show both pickup and dropoff when applicable

### 4. **Document Services Form** (category: `document_services`)
- **Stores:**
  - `location_address` = Primary service location
  - `pickup_location` = Where to collect (if "collect and deliver" option)
- **Issue:** Similar to license discs

### 5. **Elderly Services Form** (category: `elderly_services`)
- **Stores:**
  - `location_address` = Service location
- **Status:** ✅ Already working correctly

### 6. **Queue Sitting Form** (category: `queue_sitting`)
- **Stores:**
  - `location_address` = Queue location
- **Status:** ✅ Already working correctly

## Solution Implemented

Created an intelligent location display helper method that:
1. Checks the errand category
2. Determines which location field(s) to display based on category
3. Formats the location appropriately (pickup → delivery for routes)
4. Truncates long addresses for better UI display
5. Provides fallbacks for missing data

### Files Modified

#### 1. `lib/widgets/errand_card.dart`
- Added `_getDisplayLocation()` method
- Updated location display in both card view (line 158) and detailed view (line 327)

#### 2. `lib/pages/runner_dashboard_page.dart`
- Added `_getDisplayLocation(errand)` method
- Updated location display in errand cards (line 1002)

### Display Logic by Category

```dart
switch (category) {
  case 'shopping':
    // Show delivery address with prefix
    return 'Deliver to: ${delivery_address}';
  
  case 'delivery':
    // Show pickup → delivery route
    return 'PickupLocation → DeliveryLocation';
  
  case 'document_services':
  case 'license_discs':
    // Show pickup → dropoff if both exist
    // Otherwise show whichever is available
    return 'Pickup → Dropoff' or 'Pickup: Location';
  
  case 'elderly_services':
  case 'queue_sitting':
  default:
    // Show primary location_address
    return location_address;
}
```

## Testing Recommendations

To verify the fix works correctly:

1. **Shopping Service:**
   - Create a shopping request with store location and delivery address
   - Verify runner sees "Deliver to: [delivery address]" not store names

2. **Delivery Service:**
   - Create a delivery request with pickup and delivery locations
   - Verify runner sees "Pickup → Delivery" route format

3. **License Discs:**
   - Create a "collect and deliver" license disc request
   - Verify runner sees both pickup and dropoff locations

4. **Document Services:**
   - Create both "drop off only" and "collect and deliver" requests
   - Verify appropriate location display

5. **Other Services:**
   - Verify elderly services and queue sitting still display correctly

## Benefits

✅ Runners now see the **correct** location based on service type
✅ Route-based services (delivery, license discs) show full route
✅ Shopping services show delivery destination, not store names
✅ Smart truncation prevents UI overflow
✅ Consistent experience across Available Errands and Runner Dashboard
✅ Backward compatible with existing data

## Edge Cases Handled

- Missing location fields → Shows "Location TBD"
- Long addresses → Truncated to 20 chars + "..."
- Null/empty values → Gracefully falls back to alternatives
- Mixed field naming (pickup_address vs pickup_location) → Checks both

## Future Considerations

If new service forms are added:
1. Add the category to the switch statement in `_getDisplayLocation()`
2. Map the appropriate location fields for that service type
3. Consider whether it's a route (pickup → delivery) or single location service

