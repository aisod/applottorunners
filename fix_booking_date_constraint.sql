-- Fix booking_date constraint to allow null values for immediate bookings
-- This allows immediate bookings (Request Now) to have null booking_date

-- First, let's check the current constraint
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'transportation_bookings' 
    AND kcu.column_name = 'booking_date';

-- Drop the existing NOT NULL constraint on booking_date
ALTER TABLE transportation_bookings 
ALTER COLUMN booking_date DROP NOT NULL;

-- Add a new constraint that allows null for immediate bookings
ALTER TABLE transportation_bookings 
ADD CONSTRAINT check_booking_date_for_scheduled 
CHECK (
    (is_immediate = true AND booking_date IS NULL) OR
    (is_immediate = false AND booking_date IS NOT NULL)
);

-- Also add a similar constraint for booking_time
ALTER TABLE transportation_bookings 
ALTER COLUMN booking_time DROP NOT NULL;

ALTER TABLE transportation_bookings 
ADD CONSTRAINT check_booking_time_for_scheduled 
CHECK (
    (is_immediate = true AND booking_time IS NULL) OR
    (is_immediate = false AND booking_time IS NOT NULL)
);

-- Add comments to document the constraints
COMMENT ON CONSTRAINT check_booking_date_for_scheduled ON transportation_bookings IS 
'Ensures booking_date is null for immediate bookings and not null for scheduled bookings';

COMMENT ON CONSTRAINT check_booking_time_for_scheduled ON transportation_bookings IS 
'Ensures booking_time is null for immediate bookings and not null for scheduled bookings';

-- Show the updated table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'transportation_bookings' 
    AND column_name IN ('booking_date', 'booking_time', 'is_immediate')
ORDER BY ordinal_position;

-- Test the constraint with sample data
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

-- Show the test results
SELECT 
    id,
    pickup_location,
    booking_date,
    booking_time,
    is_immediate,
    created_at
FROM transportation_bookings 
ORDER BY created_at DESC 
LIMIT 5;
