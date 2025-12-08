-- Test Booking Creation
-- This script tests that transportation bookings can be created correctly

-- 1. Check current constraints
SELECT 'Current constraints:' as info;
SELECT 
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'transportation_bookings'
    AND tc.constraint_type = 'CHECK';

-- 2. Test immediate booking creation
SELECT 'Testing immediate booking creation:' as info;
INSERT INTO transportation_bookings (
    user_id, 
    vehicle_type_id, 
    pickup_location, 
    dropoff_location, 
    passenger_count, 
    is_immediate, 
    status, 
    payment_status
) VALUES (
    (SELECT id FROM users LIMIT 1),
    (SELECT id FROM vehicle_types LIMIT 1),
    'Test Pickup Location',
    'Test Dropoff Location',
    2,
    true,
    'pending',
    'pending'
) RETURNING id, pickup_location, dropoff_location, is_immediate, created_at;

-- 3. Test scheduled booking creation
SELECT 'Testing scheduled booking creation:' as info;
INSERT INTO transportation_bookings (
    user_id, 
    vehicle_type_id, 
    pickup_location, 
    dropoff_location, 
    passenger_count, 
    booking_date, 
    booking_time, 
    is_immediate, 
    status, 
    payment_status
) VALUES (
    (SELECT id FROM users LIMIT 1),
    (SELECT id FROM vehicle_types LIMIT 1),
    'Test Pickup Location 2',
    'Test Dropoff Location 2',
    1,
    '2024-01-20',
    '15:30',
    false,
    'pending',
    'pending'
) RETURNING id, pickup_location, dropoff_location, booking_date, booking_time, is_immediate, created_at;

-- 4. Show recent bookings
SELECT 'Recent transportation bookings:' as info;
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

-- 5. Check if notifications were created
SELECT 'Recent notifications:' as info;
SELECT 
    n.title,
    n.message,
    n.type,
    n.is_read,
    n.created_at,
    u.full_name as recipient
FROM notifications n
JOIN users u ON n.user_id = u.id
ORDER BY n.created_at DESC
LIMIT 5;
