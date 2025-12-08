# Transport Booking Pricing Fix

## Issue Description
The transport booking form is unable to calculate pricing due to database schema mismatches and missing pricing data.

## Root Causes Identified

### 1. Database Schema Mismatch
- **Problem**: Two different `vehicle_types` table definitions exist
  - `transportation_system.sql` - Basic table without pricing fields
  - `vehicle_pricing_system.sql` - Extended table with pricing fields
- **Impact**: The pricing calculation function expects pricing columns that may not exist

### 2. Function Parameter Mismatch
- **Problem**: The `calculate_transportation_price` database function was missing the `pickup_fee` parameter
- **Impact**: Flutter code calls the function with pickup fee but function doesn't accept it

### 3. Missing Sample Data
- **Problem**: No vehicle types with pricing information exist in the database
- **Impact**: Pricing calculation returns null values

## Solution

### Step 1: Run the Database Fix Script
Execute the `fix_vehicle_pricing_schema.sql` script in your Supabase SQL editor:

```sql
-- This script will:
-- 1. Add missing pricing columns to vehicle_types table
-- 2. Create required pricing tables
-- 3. Add missing columns to transportation_bookings table
-- 4. Create transportation_booking_pricing table
-- 5. Fix the calculate_transportation_price function
-- 6. Insert sample vehicle data with pricing
```

### Step 2: Verify the Fix
Run the test script `test_pricing_function.sql` to verify everything works:

```sql
-- This will test the pricing function with sample data
SELECT * FROM calculate_transportation_price(
  (SELECT id FROM vehicle_types WHERE name = 'Sedan' LIMIT 1),
  10.0, -- 10 km distance
  'individual', -- user type
  5.0 -- pickup fee
);
```

### Step 3: Test the Flutter App
1. Run the app with debugging enabled
2. Navigate to the transport booking form
3. Select a vehicle type
4. Enter pickup and dropoff locations
5. Check the console for debugging output

## Expected Behavior After Fix

### Pricing Calculation Formula
```
Total Price = Base Price + (Distance × Price per KM)

For Individual Users:
Applied Price = Base Price + (Distance × Price per KM)

For Business Users:
Applied Price = Business Price + (Distance × Price per KM)
```

### Sample Pricing (Sedan Example)
- **Base Price**: NAD 50.00
- **Business Price**: NAD 75.00
- **Price per KM**: NAD 2.50
- **Distance**: 20 km

**Individual User Total**: 50.00 + (20 × 2.50) = **NAD 100.00**
**Business User Total**: 75.00 + (20 × 2.50) = **NAD 125.00**

## Debugging

### Console Output to Look For
```
Starting pricing calculation...
Selected vehicle ID: [UUID]
User type: individual
Calculating distance between: [pickup] and [dropoff]
Distance calculated: [X] km
Calling calculateTransportationPrice with: vehicleTypeId=[UUID], distanceKm=[X], userType=individual
Pricing result: [pricing object]
```

### Common Issues and Solutions

#### Issue: "Function calculate_transportation_price does not exist"
**Solution**: Run the `fix_vehicle_pricing_schema.sql` script

#### Issue: "Column price_base does not exist"
**Solution**: The script will add missing columns automatically

#### Issue: "No pricing data returned"
**Solution**: Check if vehicle types have pricing data in the database

#### Issue: "Distance calculation fails"
**Solution**: Verify Google Maps API key is configured in LocationService

## Files Modified

### 1. `fix_vehicle_pricing_schema.sql`
- Comprehensive database schema fix
- Creates missing tables and columns
- Inserts sample data

### 2. `lib/supabase/vehicle_pricing_system.sql`
- Updated pricing function with pickup fee support
- Added sample vehicle data

### 3. `lib/pages/transportation_page.dart`
- Added debugging output for pricing calculation
- Added debugging for vehicle loading

### 4. `lib/supabase/supabase_config.dart`
- Added debugging to pricing calculation method

## Testing Checklist

- [ ] Database schema fix script executed successfully
- [ ] Sample vehicle data exists with pricing
- [ ] Pricing function returns correct values
- [ ] Flutter app loads vehicles without errors
- [ ] Distance calculation works
- [ ] Pricing calculation completes successfully
- [ ] Pricing breakdown displays correctly
- [ ] Booking submission works with calculated pricing

## Support

If issues persist after following these steps:
1. Check the console output for specific error messages
2. Verify the database schema matches the expected structure
3. Ensure all required tables and functions exist
4. Check if the Google Maps API key is valid for distance calculations
