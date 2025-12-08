# Restore Contract Subscription Subcategory

## Issue
The "Contract Subscription" subcategory was accidentally removed during the implementation of vehicle filtering by subcategory. This subcategory is essential for business transportation contracts.

## Solution Implemented

### 1. Database Changes Required

#### Run the Contract Subscription addition script:
```sql
-- Execute this in your Supabase SQL editor
\i lib/supabase/add_contract_subscription.sql
```

This script will:
- Add "Contract Subscription" as a new subcategory
- Set appropriate sort order (after Shuttle Services)
- Update existing subcategory sort orders

#### Run the vehicle subcategory association script:
```sql
-- Execute this in your Supabase SQL editor
\i lib/supabase/update_vehicle_subcategories.sql
```

This script will:
- Associate vehicles with Contract Subscription subcategory
- Map Large Van, Minibus, and Cargo Van to Contract Subscription

### 2. Code Changes Made

#### Updated SupabaseConfig (`lib/supabase/supabase_config.dart`):
- Added "Contract Subscription" to `getTransportationSubcategories()` method
- Now includes all 7 transportation subcategories

#### Updated Service Selector (`lib/widgets/service_selector.dart`):
- Fixed subtitle text to show "Business Contracts" for Contract Subscription
- Shows "On-Demand Vehicles" for Shuttle Services
- Shows "Scheduled Services" for other services

### 3. New Subcategory Structure

The transportation subcategories now include:
1. **Bus Services** - Scheduled bus routes
2. **Shuttle Services** - Door-to-door shuttle services  
3. **Contract Subscription** - Long-term business contracts
4. **Ride Sharing** - Individual and group ride sharing
5. **Airport Transfers** - Airport pickup and drop-off
6. **Cargo Transport** - Commercial cargo transportation
7. **Moving Services** - Household and office moving

### 4. Vehicle Mappings for Contract Subscription

When users select "Contract Subscription", they will see:
- **Large Van** (12 seats) - for business groups
- **Minibus** (23 seats) - for larger business groups
- **Cargo Van** (2 seats) - for business cargo needs

### 5. Testing the Restoration

1. **Run both SQL scripts** in Supabase
2. **Verify Contract Subscription appears** in the service type selection
3. **Select Contract Subscription** - should show business vehicles only
4. **Check subtitle shows** "Business Contracts" for Contract Subscription
5. **Verify vehicle filtering** works correctly for all subcategories

### 6. Expected UI Behavior

- **Shuttle Services**: Shows personal vehicles with "On-Demand Vehicles" subtitle
- **Contract Subscription**: Shows business vehicles with "Business Contracts" subtitle  
- **Bus Services**: Shows bus vehicles with "Scheduled Services" subtitle
- **Other services**: Show appropriate vehicles with "Scheduled Services" subtitle

## Next Steps

1. Execute both SQL scripts in Supabase
2. Test the Contract Subscription subcategory selection
3. Verify vehicle filtering works for all subcategories
4. Ensure the UI properly displays all three main service types
5. Test the complete transportation booking flow

The Contract Subscription subcategory should now be fully restored and functional.
