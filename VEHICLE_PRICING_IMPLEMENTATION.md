# Vehicle Pricing System Implementation

## Overview
This document describes the implementation of a comprehensive vehicle pricing system for the Lotto Runners transportation platform. The system includes base and business pricing, distance-based calculations, and Google Maps integration for accurate route calculations.

## Features Implemented

### 1. Dual Pricing Structure
- **Base Price**: Standard pricing for individual users
- **Business Price**: Premium pricing for business users (typically higher)
- **Price per KM**: Distance-based pricing component
- **Pickup Fee**: Additional fee for pickup service

### 2. Distance-Based Calculations
- **Google Maps Integration**: Uses Google Maps Directions API for accurate route calculations
- **Fallback Calculation**: Haversine formula for direct distance when API is unavailable
- **Real-time Updates**: Pricing recalculates automatically when locations change

### 3. User Type Differentiation
- **Individual Users**: See and pay base pricing
- **Business Users**: See and pay business pricing
- **Automatic Detection**: User type is automatically detected from profile

## Database Schema

### New Tables Created

#### 1. vehicle_pricing
```sql
CREATE TABLE vehicle_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type_id UUID REFERENCES vehicle_types(id) ON DELETE CASCADE,
  pricing_type VARCHAR(20) CHECK (pricing_type IN ('fixed', 'per_km', 'tiered', 'hybrid')),
  base_price DECIMAL(10, 2) NOT NULL,
  business_price DECIMAL(10, 2) NOT NULL,
  price_per_km DECIMAL(8, 2) DEFAULT 0.00,
  pickup_fee DECIMAL(8, 2) DEFAULT 0.00,
  minimum_fare DECIMAL(8, 2) DEFAULT 0.00,
  maximum_fare DECIMAL(8, 2),
  weekend_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  holiday_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  peak_hour_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. vehicle_pricing_tiers
```sql
CREATE TABLE vehicle_pricing_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type_id UUID REFERENCES vehicle_types(id) ON DELETE CASCADE,
  min_distance_km DECIMAL(8, 2) NOT NULL,
  max_distance_km DECIMAL(8, 2),
  base_price DECIMAL(10, 2) NOT NULL,
  business_price DECIMAL(10, 2) NOT NULL,
  price_per_km DECIMAL(8, 2) DEFAULT 0.00,
  tier_name VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vehicle_type_id, min_distance_km)
);
```

#### 3. transportation_booking_pricing
```sql
CREATE TABLE transportation_booking_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES transportation_bookings(id) ON DELETE CASCADE,
  vehicle_type_id UUID REFERENCES vehicle_types(id),
  base_price DECIMAL(10, 2) NOT NULL,
  business_price DECIMAL(10, 2) NOT NULL,
  distance_km DECIMAL(8, 2) NOT NULL,
  price_per_km DECIMAL(8, 2) DEFAULT 0.00,
  pickup_fee DECIMAL(8, 2) DEFAULT 0.00,
  distance_cost DECIMAL(10, 2) DEFAULT 0.00,
  total_base_price DECIMAL(10, 2) NOT NULL,
  total_business_price DECIMAL(10, 2) NOT NULL,
  applied_price DECIMAL(10, 2) NOT NULL,
  user_type VARCHAR(20) DEFAULT 'individual',
  pricing_breakdown JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Updated Tables

#### vehicle_types
Added new pricing fields:
```sql
ALTER TABLE vehicle_types 
ADD COLUMN price_base DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN price_business DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN price_per_km DECIMAL(8, 2) DEFAULT 0.00,
ADD COLUMN pickup_fee DECIMAL(8, 2) DEFAULT 0.00;
```

## API Functions

### 1. calculate_transportation_price
```sql
CREATE OR REPLACE FUNCTION calculate_transportation_price(
  p_vehicle_type_id UUID,
  p_distance_km DECIMAL,
  p_user_type VARCHAR DEFAULT 'individual',
  p_pickup_fee DECIMAL DEFAULT 0.00
)
RETURNS TABLE(
  base_price DECIMAL,
  business_price DECIMAL,
  distance_cost DECIMAL,
  pickup_fee DECIMAL,
  total_base_price DECIMAL,
  total_business_price DECIMAL,
  applied_price DECIMAL
)
```

### 2. calculate_distance_km
```sql
CREATE OR REPLACE FUNCTION calculate_distance_km(
  lat1 DECIMAL,
  lon1 DECIMAL,
  lat2 DECIMAL,
  lon2 DECIMAL
)
RETURNS DECIMAL
```

## Frontend Implementation

### 1. Location Service Updates
- **Distance Calculation**: Added Haversine formula and Google Maps API integration
- **Route Information**: Returns distance, duration, and mode of transportation
- **Fallback Support**: Works without Google API key using basic geocoding

### 2. Transportation Management Page
- **Vehicle Pricing**: Admin can set base and business prices for each vehicle type
- **Pricing Tiers**: Support for distance-based pricing tiers
- **Real-time Updates**: Pricing changes reflect immediately in the UI

### 3. Transportation Booking Page
- **Automatic Pricing**: Calculates pricing based on selected vehicle and locations
- **User Type Detection**: Automatically shows appropriate pricing for user type
- **Distance Display**: Shows calculated distance and pricing breakdown
- **Real-time Updates**: Recalculates when locations or vehicle selection changes

## Pricing Calculation Logic

### Formula
```
Total Price = Base Price + (Distance × Price per KM) + Pickup Fee

For Business Users:
Applied Price = Business Price + (Distance × Price per KM) + Pickup Fee

For Individual Users:
Applied Price = Base Price + (Distance × Price per KM) + Pickup Fee
```

### Example
- **Vehicle**: Sedan
- **Base Price**: NAD 50.00
- **Business Price**: NAD 75.00
- **Price per KM**: NAD 2.50
- **Pickup Fee**: NAD 10.00
- **Distance**: 20 km

**Individual User Total**: 50.00 + (20 × 2.50) + 10.00 = NAD 110.00
**Business User Total**: 75.00 + (20 × 2.50) + 10.00 = NAD 135.00

## Google Maps Integration

### Features
1. **Directions API**: Calculates actual driving distance and duration
2. **Geocoding**: Converts addresses to coordinates
3. **Fallback Support**: Works without API key using basic calculations
4. **Real-time Updates**: Pricing updates as user types addresses

### API Endpoints Used
- **Directions API**: `/maps/api/directions/json`
- **Places API**: `/maps/api/place/autocomplete/json`
- **Geocoding API**: Basic geocoding for fallback

### Configuration
- API key can be set via environment variable or hardcoded
- Graceful degradation when API is unavailable
- Namibia-specific location suggestions

## Admin Features

### 1. Vehicle Type Management
- Add/edit vehicle types with pricing information
- Set base price, business price, price per KM, and pickup fee
- Manage pricing tiers for different distance ranges

### 2. Pricing Tiers
- **Local**: 0-10 km pricing
- **Regional**: 10-50 km pricing
- **Long Distance**: 50+ km pricing
- Custom tier creation and management

### 3. Real-time Updates
- Pricing changes reflect immediately
- Support for bulk pricing updates
- Historical pricing tracking

## User Experience

### 1. Individual Users
- See base pricing only
- Transparent pricing breakdown
- Distance-based cost calculation
- No business pricing confusion

### 2. Business Users
- See business pricing prominently
- Premium service indication
- Same transparent breakdown
- Professional pricing structure

### 3. Booking Process
1. Select transportation category
2. Choose vehicle type
3. Enter pickup and dropoff locations
4. View automatic price calculation
5. See pricing breakdown
6. Submit booking with calculated price

## Security and Access Control

### RLS Policies
- **Public Read**: Active pricing information is publicly readable
- **User Access**: Users can only see their own booking pricing
- **Admin Access**: Full CRUD access for administrators
- **Data Protection**: Sensitive pricing data protected by user type

### User Type Validation
- Automatic user type detection
- Business user verification
- Pricing access control
- Audit trail for pricing changes

## Testing and Validation

### Test Scenarios
1. **Individual User Booking**
   - Verify base pricing display
   - Confirm distance calculations
   - Test price breakdown accuracy

2. **Business User Booking**
   - Verify business pricing display
   - Confirm premium pricing application
   - Test user type detection

3. **Admin Management**
   - Test vehicle pricing creation
   - Verify pricing tier management
   - Confirm real-time updates

4. **Distance Calculations**
   - Test Google Maps API integration
   - Verify fallback calculations
   - Confirm accuracy across different locations

## Deployment Instructions

### 1. Database Setup
```sql
-- Run the vehicle_pricing_system.sql file
-- This creates all necessary tables and functions
```

### 2. Frontend Updates
- Update location service with new distance calculation methods
- Deploy updated transportation management page
- Deploy updated transportation booking page

### 3. Google Maps Setup
- Configure Google Maps API key
- Enable required APIs (Directions, Places, Geocoding)
- Set up platform-specific configurations

### 4. Testing
- Test pricing calculations with sample data
- Verify user type detection
- Test distance calculations with known routes
- Validate admin pricing management

## Future Enhancements

### 1. Advanced Pricing Models
- **Time-based Pricing**: Peak/off-peak hour multipliers
- **Seasonal Pricing**: Holiday and weekend multipliers
- **Dynamic Pricing**: Demand-based pricing adjustments

### 2. Additional Features
- **Route Optimization**: Multiple stop routing
- **Fleet Management**: Vehicle availability tracking
- **Analytics**: Pricing performance metrics
- **A/B Testing**: Pricing strategy testing

### 3. Integration Opportunities
- **Payment Gateways**: Direct payment processing
- **Accounting Systems**: Automated invoicing
- **CRM Integration**: Customer relationship management
- **Reporting Tools**: Advanced analytics and reporting

## Troubleshooting

### Common Issues
1. **Pricing Not Calculating**
   - Check vehicle pricing configuration
   - Verify location coordinates
   - Check Google Maps API key

2. **Distance Calculation Errors**
   - Verify address format
   - Check internet connectivity
   - Review API usage limits

3. **User Type Detection Issues**
   - Check user profile configuration
   - Verify database permissions
   - Review authentication flow

### Support Resources
- Database schema documentation
- API endpoint documentation
- Frontend component documentation
- Google Maps API documentation

## Conclusion

The vehicle pricing system provides a robust, scalable solution for transportation pricing with the following benefits:

- **Flexible Pricing**: Support for multiple pricing models and tiers
- **User Differentiation**: Clear pricing for individual vs. business users
- **Accurate Calculations**: Google Maps integration for precise distance calculations
- **Admin Control**: Comprehensive pricing management tools
- **User Experience**: Transparent pricing with real-time updates
- **Scalability**: Support for complex pricing structures and future enhancements

This implementation establishes a solid foundation for transportation pricing while maintaining flexibility for future business requirements and pricing strategies.
