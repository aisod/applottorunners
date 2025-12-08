-- Test Database Setup for Transportation Booking System
-- Run this in your Supabase SQL editor to verify everything is set up correctly

-- 1. Check if required tables exist
SELECT 'Checking required tables...' as test_status;

SELECT 
  table_name,
  CASE 
    WHEN table_name IN ('vehicle_types', 'transportation_bookings', 'transportation_booking_pricing', 'vehicle_pricing') 
    THEN '✅ EXISTS' 
    ELSE '❌ MISSING' 
  END as status
FROM information_schema.tables 
WHERE table_name IN ('vehicle_types', 'transportation_bookings', 'transportation_booking_pricing', 'vehicle_pricing')
AND table_schema = 'public';

-- 2. Check if vehicle_types has required columns
SELECT 'Checking vehicle_types columns...' as test_status;

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'vehicle_types' 
AND column_name IN ('id', 'name', 'price_base', 'price_business', 'price_per_km', 'is_active')
ORDER BY column_name;

-- 3. Check if there are any vehicle types with pricing
SELECT 'Checking vehicle types with pricing...' as test_status;

SELECT 
  id, 
  name, 
  price_base, 
  price_business, 
  price_per_km,
  is_active
FROM vehicle_types 
WHERE is_active = true
LIMIT 5;

-- 4. Check if the pricing function exists
SELECT 'Checking pricing function...' as test_status;

SELECT 
  routine_name, 
  routine_type, 
  data_type 
FROM information_schema.routines 
WHERE routine_name = 'calculate_transportation_price'
AND routine_schema = 'public';

-- 5. Test the pricing function with a real vehicle type
SELECT 'Testing pricing function...' as test_status;

-- First get a vehicle type ID
WITH vehicle_check AS (
  SELECT id, name, price_base, price_business, price_per_km
  FROM vehicle_types 
  WHERE is_active = true 
  AND price_base > 0 
  LIMIT 1
)
SELECT 
  'Vehicle found: ' || name as vehicle_info,
  'Base price: ' || price_base as base_price_info,
  'Business price: ' || price_business as business_price_info,
  'Price per KM: ' || price_per_km as price_per_km_info
FROM vehicle_check;

-- 6. Test the pricing function
SELECT 'Testing calculate_transportation_price function...' as test_status;

SELECT * FROM calculate_transportation_price(
  (SELECT id FROM vehicle_types WHERE is_active = true AND price_base > 0 LIMIT 1),
  10.0, -- 10 km distance
  'individual' -- user type
);

-- 7. Check if transportation_bookings table exists and has required columns
SELECT 'Checking transportation_bookings table...' as test_status;

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'transportation_bookings' 
AND column_name IN ('id', 'user_id', 'vehicle_type_id', 'pickup_location', 'dropoff_location', 'passenger_count', 'booking_date', 'booking_time', 'estimated_price', 'status')
ORDER BY column_name;

-- 8. Check if create_transportation_booking_with_pricing function exists
SELECT 'Checking booking creation function...' as test_status;

SELECT 
  routine_name, 
  routine_type, 
  data_type 
FROM information_schema.routines 
WHERE routine_name = 'create_transportation_booking_with_pricing'
AND routine_schema = 'public';

-- 9. Summary
SELECT 'Database setup verification complete!' as completion_status;
