-- Test script for the calculate_transportation_price function
-- Run this in your Supabase SQL editor to test the function

-- First, let's check if the function exists
SELECT 
  routine_name, 
  routine_type, 
  data_type 
FROM information_schema.routines 
WHERE routine_name = 'calculate_transportation_price';

-- Check if vehicle_types table has the required pricing columns
SELECT 
  column_name, 
  data_type, 
  is_nullable 
FROM information_schema.columns 
WHERE table_name = 'vehicle_types' 
AND column_name IN ('price_base', 'price_business', 'price_per_km');

-- Check if there are any vehicle types with pricing data
SELECT 
  id, 
  name, 
  price_base, 
  price_business, 
  price_per_km 
FROM vehicle_types 
WHERE is_active = true;

-- Test the function with sample data
-- Replace the UUID with an actual vehicle type ID from your database
SELECT * FROM calculate_transportation_price(
  '00000000-0000-0000-0000-000000000001'::UUID, -- Replace with actual vehicle type ID
  10.0, -- 10 km distance
  'individual' -- user type
);

-- If the above fails, let's test with a simpler approach
-- First, let's see what vehicle types exist
SELECT 
  id, 
  name, 
  price_base, 
  price_business, 
  price_per_km 
FROM vehicle_types 
LIMIT 5;

-- Then test with the first available vehicle type
-- (Replace the UUID below with an actual ID from the query above)
SELECT * FROM calculate_transportation_price(
  (SELECT id FROM vehicle_types LIMIT 1), -- Use first available vehicle type
  10.0, -- 10 km distance
  'individual' -- user type
);
