-- Fix Booking Constraint Issue
-- This script fixes the constraint that's preventing immediate bookings from being created

-- 1. First, let's check what constraints exist
SELECT 
    tc.constraint_name,
    tc.table_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'transportation_bookings'
    AND tc.constraint_type = 'CHECK';

-- 2. Drop the problematic constraints
ALTER TABLE transportation_bookings 
DROP CONSTRAINT IF EXISTS check_booking_date_for_scheduled;

ALTER TABLE transportation_bookings 
DROP CONSTRAINT IF EXISTS check_booking_time_for_scheduled;

-- 3. Create more flexible constraints that handle the actual data structure
ALTER TABLE transportation_bookings 
ADD CONSTRAINT check_booking_date_for_scheduled 
CHECK (
    -- Allow immediate bookings to have null or current date
    (is_immediate = true) OR
    -- For scheduled bookings, require a date
    (is_immediate = false AND booking_date IS NOT NULL)
);

ALTER TABLE transportation_bookings 
ADD CONSTRAINT check_booking_time_for_scheduled 
CHECK (
    -- Allow immediate bookings to have null or current time
    (is_immediate = true) OR
    -- For scheduled bookings, require a time
    (is_immediate = false AND booking_time IS NOT NULL)
);

-- 4. Update existing records to ensure they meet the constraints
-- Set is_immediate = true for records with null dates
UPDATE transportation_bookings 
SET is_immediate = true 
WHERE booking_date IS NULL AND booking_time IS NULL;

-- Set is_immediate = false for records with dates
UPDATE transportation_bookings 
SET is_immediate = false 
WHERE booking_date IS NOT NULL AND booking_time IS NOT NULL;

-- 5. Test the constraint with sample data
-- This should work for immediate booking
INSERT INTO transportation_bookings (
    user_id, vehicle_type_id, pickup_location, dropoff_location, 
    passenger_count, is_immediate, status, payment_status
) VALUES (
    (SELECT id FROM users LIMIT 1),
    (SELECT id FROM vehicle_types LIMIT 1),
    'Test Pickup',
    'Test Dropoff',
    1,
    true,
    'pending',
    'pending'
) ON CONFLICT DO NOTHING;

-- This should work for scheduled booking
INSERT INTO transportation_bookings (
    user_id, vehicle_type_id, pickup_location, dropoff_location, 
    passenger_count, booking_date, booking_time, is_immediate, status, payment_status
) VALUES (
    (SELECT id FROM users LIMIT 1),
    (SELECT id FROM vehicle_types LIMIT 1),
    'Test Pickup 2',
    'Test Dropoff 2',
    1,
    '2024-01-15',
    '14:30',
    false,
    'pending',
    'pending'
) ON CONFLICT DO NOTHING;

-- 6. Show the results
SELECT 
    id,
    pickup_location,
    dropoff_location,
    is_immediate,
    booking_date,
    booking_time,
    status,
    created_at
FROM transportation_bookings 
ORDER BY created_at DESC 
LIMIT 5;

-- 7. Show the current constraints
SELECT 
    tc.constraint_name,
    tc.table_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'transportation_bookings'
    AND tc.constraint_type = 'CHECK';
