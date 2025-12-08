-- Test Notification System
-- This script helps verify that the notification system is working correctly

-- 1. Check if notifications table exists and has data
SELECT 'Notifications table check:' as info;
SELECT COUNT(*) as total_notifications FROM notifications;

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
LIMIT 10;

-- 2. Check transportation bookings
SELECT 'Recent transportation bookings:' as info;
SELECT 
    tb.id,
    tb.pickup_location,
    tb.dropoff_location,
    tb.is_immediate,
    tb.status,
    vt.name as vehicle_type,
    u.full_name as customer,
    tb.created_at
FROM transportation_bookings tb
JOIN vehicle_types vt ON tb.vehicle_type_id = vt.id
JOIN users u ON tb.user_id = u.id
ORDER BY tb.created_at DESC
LIMIT 10;

-- 3. Check runner applications
SELECT 'Approved runners by vehicle type:' as info;
SELECT 
    ra.vehicle_type,
    COUNT(ra.user_id) as runner_count,
    STRING_AGG(u.full_name, ', ') as runner_names
FROM runner_applications ra
JOIN users u ON ra.user_id = u.id
WHERE ra.verification_status = 'approved'
GROUP BY ra.vehicle_type
ORDER BY ra.vehicle_type;

-- 4. Test notification matching logic
SELECT 'Testing notification matching for SUV:' as info;
WITH test_booking AS (
    SELECT 
        'SUV' as vehicle_type_name,
        'Test Pickup' as pickup_location,
        'Test Dropoff' as dropoff_location
)
SELECT 
    tb.vehicle_type_name,
    ra.vehicle_type as runner_vehicle_type,
    CASE 
        WHEN LOWER(tb.vehicle_type_name) = LOWER(ra.vehicle_type) THEN 'MATCH'
        ELSE 'NO MATCH'
    END as match_status,
    u.full_name as runner_name
FROM test_booking tb
CROSS JOIN runner_applications ra
JOIN users u ON ra.user_id = u.id
WHERE ra.verification_status = 'approved'
ORDER BY match_status, u.full_name;

-- 5. Check for any immediate bookings that should have triggered notifications
SELECT 'Immediate bookings that should trigger notifications:' as info;
SELECT 
    tb.id,
    tb.pickup_location,
    tb.dropoff_location,
    vt.name as vehicle_type,
    tb.is_immediate,
    tb.created_at,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM runner_applications ra 
            WHERE ra.verification_status = 'approved' 
            AND LOWER(ra.vehicle_type) = LOWER(vt.name)
        ) THEN 'SHOULD NOTIFY'
        ELSE 'NO RUNNERS AVAILABLE'
    END as notification_status
FROM transportation_bookings tb
JOIN vehicle_types vt ON tb.vehicle_type_id = vt.id
WHERE tb.is_immediate = true
ORDER BY tb.created_at DESC;
