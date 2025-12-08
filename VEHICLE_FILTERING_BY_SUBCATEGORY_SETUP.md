# Vehicle Filtering by Subcategory Setup Guide

## Overview
This guide explains how to set up the vehicle filtering system so that when users select a subcategory (like "Shuttle Services" or "Contract Subscription"), only relevant vehicles are displayed.

## Current Issue
The system was not properly filtering vehicles based on subcategory selection. Vehicles were being shown regardless of which subcategory was selected.

## Solution Implemented

### 1. Database Setup Required

#### Run the vehicle subcategory association script:
```sql
-- Execute this in your Supabase SQL editor
\i lib/supabase/update_vehicle_subcategories.sql
```

This script will:
- Associate each vehicle type with the appropriate service subcategories
- Ensure vehicles are properly categorized for filtering

#### Vehicle-Subcategory Mappings:
- **Bus Services**: Minibus, Bus
- **Shuttle Services**: Sedan, Hatchback, Minivan  
- **Contract Subscription**: Large Van, Minibus, Cargo Van
- **Ride Sharing**: Sedan, Hatchback
- **Airport Transfers**: Sedan, Hatchback, Minivan, Large Van
- **Cargo Transport**: Pickup Truck, Cargo Van, Large Van
- **Moving Services**: Large Van, Cargo Van, Pickup Truck

### 2. Code Changes Made

#### Updated SupabaseConfig (`lib/supabase/supabase_config.dart`):
- Added `getTransportationSubcategories()` method to filter only transportation-related subcategories
- Updated `getVehicleTypesBySubcategory()` method to use `service_subcategory_ids` field

#### Updated Service Selector (`lib/widgets/service_selector.dart`):
- Changed to use `getTransportationSubcategories()` instead of `getServiceSubcategories()`
- Vehicles now load based on selected subcategory using `_loadVehicleTypesBySubcategory()`

#### Updated Transportation Page (`lib/pages/transportation_page.dart`):
- Changed to use `getTransportationSubcategories()` for subcategory loading
- Updated `_loadVehicles()` method to use subcategory-based filtering

### 3. How It Works Now

1. **User selects a subcategory** (e.g., "Shuttle Services")
2. **System calls** `getVehicleTypesBySubcategory(subcategoryId)`
3. **Database filters** vehicles using `service_subcategory_ids` array field
4. **Only relevant vehicles** for that subcategory are displayed
5. **Vehicle class selection** (Economic, Standard, Premium) is still available for pricing

### 4. Database Schema Requirements

The `vehicle_types` table must have:
- `service_subcategory_ids` field (UUID array) containing the IDs of subcategories this vehicle supports
- `vehicle_class` field for pricing tiers (economic, standard, premium)

### 5. Testing the Setup

1. **Run the SQL script** to update vehicle-subcategory associations
2. **Select "Shuttle Services"** - should only show: Sedan, Hatchback, Minivan
3. **Select "Bus Services"** - should only show: Minibus, Bus
4. **Select "Cargo Transport"** - should only show: Pickup Truck, Cargo Van, Large Van

### 6. Troubleshooting

#### If vehicles still show for all subcategories:
- Check that `service_subcategory_ids` field exists in `vehicle_types` table
- Verify the SQL script ran successfully
- Check that vehicle types have the correct subcategory IDs

#### If no vehicles show for any subcategory:
- Verify subcategory IDs exist in `service_subcategories` table
- Check that `service_subcategory_ids` arrays are not empty
- Ensure vehicle types are marked as `is_active = true`

## Expected Behavior

- **Shuttle Services**: Shows personal vehicles (Sedan, Hatchback, Minivan)
- **Contract Subscription**: Shows business vehicles (Large Van, Minibus, Cargo Van)
- **Bus Services**: Shows only bus-type vehicles (Minibus, Bus)
- **Each subcategory** shows only vehicles that are appropriate for that service type

## Next Steps

1. Execute the SQL script in Supabase
2. Test the filtering with different subcategory selections
3. Verify that vehicle class selection still works for pricing
4. Ensure the UI properly displays the filtered vehicle options
