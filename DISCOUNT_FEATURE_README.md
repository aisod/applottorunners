# Discount Functionality - Implementation Guide

## Overview
This document describes the new percentage-based discount functionality for Lotto Runners services (errands) and rides (transportation).

## Features Implemented

### 1. Database Schema
- **SQL Migration**: `lib/supabase/add_discount_columns.sql`
  - Adds `discount_percentage` column to `services` table (for errands)
  - Adds `discount_percentage` column to `vehicle_types` table (for rides)
  - Both columns accept values from 0 to 100 (percentage)
  - Default value is 0 (no discount)
  - Includes database indexes for performance

### 2. Backend (Supabase Config)
- **File**: `lib/supabase/supabase_config.dart`
- **New Methods**:
  - `updateServiceDiscount(serviceId, discountPercentage)` - Update errand service discount
  - `updateVehicleTypeDiscount(vehicleTypeId, discountPercentage)` - Update ride discount
  - `calculateDiscountedPrice(originalPrice, discountPercentage)` - Calculate discounted price

### 3. Admin Management Pages

#### Service Management (Errands)
- **File**: `lib/pages/admin/service_management_page.dart`
- **Features**:
  - Added discount percentage field in the service edit dialog
  - Shows discount badge on service cards (orange "X% OFF" label)
  - Validates discount is between 0-100%
  - Automatically saves discount when updating service

#### Vehicle Discount Management (Rides)
- **File**: `lib/pages/admin/vehicle_discount_management_page.dart`
- **Features**:
  - New dedicated page for managing ride discounts
  - Added to admin navigation (both sidebar and bottom nav)
  - Shows all vehicles with their current discount status
  - Statistics cards showing total rides, discounted rides, and non-discounted rides
  - Easy-to-use edit dialog for each vehicle type

### 4. Customer-Facing UI

#### Service Selection Page (Errands)
- **File**: `lib/pages/service_selection_page.dart`
- **Features**:
  - Shows original price crossed out when discount applies
  - Displays discounted price in orange
  - Shows discount badge (e.g., "10% OFF")
  - Automatically calculates discounted price based on user type (individual/business)

#### Transportation Page (Request a Ride)
- **File**: `lib/pages/transportation_page.dart`
- **Features**:
  - Shows discount in vehicle dropdown selection
  - Displays original price crossed out in pricing card
  - Shows discounted price with orange highlight
  - Shows "You save N$X.XX!" message
  - Prominent "X% Discount Applied!" badge

#### Contract Booking Page
- **File**: `lib/pages/contract_booking_page.dart`
- **Features**:
  - Shows discount badge in vehicle dropdown
  - Displays discount information in selection summary
  - Visual indication of available discounts

## How to Use

### For Administrators

#### 1. Setting Discounts for Errands
1. Navigate to **Admin Dashboard**
2. Go to **Service Management**
3. Click the menu (⋮) on any service card
4. Select **Edit**
5. Enter the discount percentage (0-100) in the "Discount Percentage (%)" field
6. Click **Save Changes**

#### 2. Setting Discounts for Rides
1. Navigate to **Admin Dashboard**
2. Go to **Ride Discounts** (new menu item)
3. Find the vehicle type you want to discount
4. Click **Edit** button on the vehicle card
5. Enter the discount percentage (0-100)
6. Click **Save**

#### 3. Removing Discounts
- Set the discount percentage to `0` to remove a discount
- The system will automatically hide discount badges when set to 0

### For Customers

#### Viewing Discounts on Errands
1. Click "Request an Errand" button on the dashboard
2. Services with discounts will show:
   - Original price crossed out
   - Discounted price in orange
   - "X% OFF" badge

#### Viewing Discounts on Rides
1. Click "Request a Ride" button on the dashboard
2. Select a vehicle type
3. If a discount applies:
   - You'll see the discount badge in the dropdown
   - The pricing card will show original vs discounted price
   - Total savings will be displayed

## Database Migration Instructions

To enable this feature, run the SQL migration:

```bash
# Connect to your Supabase database and run:
psql -h your-supabase-host -U postgres -d your-database < lib/supabase/add_discount_columns.sql
```

Or through Supabase Dashboard:
1. Go to SQL Editor
2. Copy contents of `lib/supabase/add_discount_columns.sql`
3. Paste and run the query

## Technical Details

### Discount Calculation
```dart
// Formula used for discount calculation
discountedPrice = originalPrice - (originalPrice * discountPercentage / 100)

// Example: 20% off on N$100
discountedPrice = 100 - (100 * 20 / 100) = N$80
```

### Discount Display Logic
- **Orange color** is used throughout for discount indicators
- **Crossed-out text** shows original prices
- **Bold orange text** shows discounted prices
- **Badges** use `Icons.local_offer` icon with percentage

### User Type Pricing
- Discounts apply **after** user type pricing is determined
- Business users see discount applied to their business price
- Individual users see discount applied to individual/base price

## Files Modified/Created

### New Files
1. `lib/supabase/add_discount_columns.sql` - Database migration
2. `lib/pages/admin/vehicle_discount_management_page.dart` - Ride discount management
3. `DISCOUNT_FEATURE_README.md` - This documentation

### Modified Files
1. `lib/supabase/supabase_config.dart` - Added discount methods
2. `lib/pages/home_page.dart` - Added discount management to admin nav
3. `lib/pages/admin/service_management_page.dart` - Added discount field
4. `lib/pages/service_selection_page.dart` - Display discounts for errands
5. `lib/pages/transportation_page.dart` - Display discounts for rides
6. `lib/pages/contract_booking_page.dart` - Display discounts for contracts

## Design Decisions

### Why Percentage-Based?
- More flexible than fixed amount discounts
- Easy to understand for both admins and customers
- Works well with varying price points
- Common industry standard

### Why Separate Management Pages?
- **Service Management**: For errand-related discounts (delivery, shopping, etc.)
- **Ride Discounts**: For transportation-related discounts (vehicles)
- Keeps admin interface organized and focused

### Why Orange Color?
- Stands out without being alarming (vs red)
- Associated with sales/deals in e-commerce
- Good contrast with the blue/yellow theme
- Accessible and visible

## Future Enhancements (Suggestions)

1. **Time-Limited Discounts**
   - Add start/end dates for promotions
   - Automatic activation/deactivation

2. **Category-Wide Discounts**
   - Apply discount to entire service category
   - Bulk discount operations

3. **User-Specific Discounts**
   - Loyalty discounts for frequent customers
   - First-time user discounts

4. **Discount Reporting**
   - Track total savings provided
   - Most discounted services analytics
   - Revenue impact analysis

5. **Combo Discounts**
   - Multiple services discount
   - Bundle deals

## Support

For any issues or questions regarding the discount functionality:
- Check database migration was successful
- Verify discount percentages are between 0-100
- Ensure admin users have proper permissions
- Check console logs for calculation errors

## Changelog

### Version 1.0 (Initial Release)
- Added discount_percentage columns to database
- Created admin management interfaces
- Implemented customer-facing discount displays
- Added discount calculation utilities
- Updated all relevant UI components

