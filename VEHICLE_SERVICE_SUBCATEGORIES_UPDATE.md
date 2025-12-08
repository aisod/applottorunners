# Vehicle Service Subcategories Update

## Overview
This update replaces the hardcoded vehicle class categories (Economy, Standard, Premium, Luxury) with a dynamic multi-select of service subcategories from the `service_subcategories` table. This provides more flexibility and better categorization of vehicle types based on the actual services they can provide.

## Changes Made

### 1. Database Schema Updates
- **New Table**: `vehicle_type_subcategories` - Junction table for many-to-many relationship
- **New Column**: `service_subcategory_ids` (UUID[]) in `vehicle_types` table
- **New Function**: `update_vehicle_subcategories()` for managing relationships
- **New View**: `vehicle_types_with_subcategories` for easier querying
- **Triggers**: Automatic synchronization between junction table and array column

### 2. UI Form Updates

#### Add Vehicle Type Form
- ✅ Replaced single text input for vehicle class
- ✅ Added multi-select FilterChip interface for service subcategories
- ✅ Similar to weekdays selection in transportation services
- ✅ Validation requires at least one subcategory selection

#### Edit Vehicle Type Form
- ✅ Same multi-select interface for service subcategories
- ✅ Loads existing selected subcategories
- ✅ Updates relationships when form is submitted

### 3. Backend Updates

#### SupabaseConfig Methods
- **`createVehicleType()`**: Now handles service subcategory relationships
- **`updateVehicleType()`**: Updates both vehicle data and subcategory relationships
- **`getAllVehicleTypes()`**: Returns vehicles with subcategory IDs

#### Data Flow
1. Form submits vehicle data with `service_subcategory_ids` array
2. Vehicle type is created/updated in database
3. `update_vehicle_subcategories()` function manages junction table
4. Array column is automatically synchronized via triggers

### 4. Display Updates

#### Vehicle Type Cards
- ✅ Shows selected service subcategories as purple chips
- ✅ Replaces old "Class: Economy/Standard/Premium" display
- ✅ Dynamic loading of subcategory names from database
- ✅ Fallback message when no subcategories assigned

## Benefits

### 1. **Flexibility**
- Vehicle types can now be assigned to multiple service categories
- No more rigid classification system
- Easy to add new service types without code changes

### 2. **Better Organization**
- Vehicles are categorized by actual capabilities
- Clear relationship between vehicle types and services
- Easier to find appropriate vehicles for specific service needs

### 3. **Scalability**
- New service subcategories can be added through admin interface
- No need to modify code for new vehicle classifications
- Better support for complex transportation scenarios

## Migration Steps

### 1. Run Database Migration
```sql
-- Execute the migration script
\i lib/supabase/vehicle_service_subcategories_migration.sql
```

### 2. Update Existing Vehicle Types
- Existing vehicles will have empty subcategory arrays
- Admin can edit each vehicle type to assign appropriate subcategories
- No data loss - old vehicle_class field can be safely removed later

### 3. Test the New Interface
- Create new vehicle types with service subcategories
- Edit existing vehicle types to add subcategories
- Verify display shows subcategories correctly

## Example Usage

### Creating a Vehicle Type
```dart
final vehicleData = {
  'name': 'Luxury Sedan',
  'capacity': 4,
  'description': 'Premium sedan for business travel',
  'service_subcategory_ids': [
    'uuid-for-airport-transfers',
    'uuid-for-business-travel',
    'uuid-for-ride-sharing'
  ],
  'price_base': 150.0,
  'price_business': 200.0,
  'price_per_km': 2.5,
};
```

### Display in UI
- **Before**: "Class: Premium"
- **After**: Purple chips showing "Airport Transfers", "Business Travel", "Ride Sharing"

## Technical Details

### Database Functions
- **`update_vehicle_subcategories(p_vehicle_type_id, p_subcategory_ids)`**
  - Manages junction table relationships
  - Updates array column automatically
  - Handles both insert and update scenarios

### Triggers
- **`trigger_sync_vehicle_subcategory_ids`**
  - Automatically syncs array column with junction table
  - Ensures data consistency
  - Runs on INSERT, UPDATE, DELETE operations

### Performance
- Indexes on both vehicle_type_id and subcategory_id
- Array column for quick access to subcategory IDs
- View for complex queries involving subcategory names

## Future Enhancements

### 1. **Bulk Operations**
- Bulk assign subcategories to multiple vehicles
- Import/export vehicle-subcategory relationships

### 2. **Advanced Filtering**
- Filter vehicles by service subcategory
- Search vehicles that can provide specific services

### 3. **Analytics**
- Track which service types are most popular
- Analyze vehicle utilization by service category

## Testing Checklist

- [ ] Create new vehicle type with multiple subcategories
- [ ] Edit existing vehicle type to add/remove subcategories
- [ ] Verify subcategories display correctly in vehicle cards
- [ ] Test validation (requires at least one subcategory)
- [ ] Verify database relationships are created correctly
- [ ] Test array column synchronization via triggers

## Rollback Plan

If issues arise, the system can be rolled back by:
1. Dropping the new junction table and triggers
2. Removing the array column from vehicle_types
3. Reverting the UI changes to use the old vehicle_class field
4. No data loss as the original vehicle data remains intact

The update provides a more robust and flexible system for vehicle categorization while maintaining backward compatibility and easy rollback options.
