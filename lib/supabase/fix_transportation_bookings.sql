-- Fix Transportation Bookings for Runner Dashboard
-- This script will create real transportation bookings that runners can see

-- First, let's check if we have any real users to work with
-- If not, we'll create some test users

-- Create test users if they don't exist
INSERT INTO users (id, email, full_name, user_type, is_verified, has_vehicle) VALUES
('11111111-1111-1111-1111-111111111111', 'customer1@test.com', 'Test Customer 1', 'individual', true, false),
('22222222-2222-2222-2222-222222222222', 'customer2@test.com', 'Test Customer 2', 'individual', true, false),
('33333333-3333-3333-3333-333333333333', 'runner1@test.com', 'Test Runner 1', 'runner', true, true),
('44444444-4444-4444-4444-444444444444', 'runner2@test.com', 'Test Runner 2', 'runner', true, true)
ON CONFLICT (id) DO NOTHING;

-- Create test transportation services if they don't exist
INSERT INTO transportation_services (id, subcategory_id, provider_id, vehicle_type_id, route_id, name, description, is_active) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 
 (SELECT id FROM service_subcategories WHERE name = 'Shuttle Services' LIMIT 1),
 (SELECT id FROM service_providers WHERE name = 'City Shuttle Services' LIMIT 1),
 (SELECT id FROM vehicle_types WHERE name = 'Minivan' LIMIT 1),
 (SELECT id FROM routes WHERE name = 'Windhoek to Swakopmund' LIMIT 1),
 'Test Shuttle Service', 'Test shuttle service for debugging', true)
ON CONFLICT (id) DO NOTHING;

-- Create test transportation bookings that runners can see
INSERT INTO transportation_bookings (
    id,
    user_id, 
    service_id, 
    pickup_location, 
    dropoff_location,
    passenger_count, 
    booking_date, 
    booking_time, 
    estimated_price,
    status, 
    special_requests,
    booking_reference
) VALUES
-- Pending booking that any runner can accept
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
 '11111111-1111-1111-1111-111111111111',
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
 'Windhoek City Center',
 'Eros Airport',
 2,
 CURRENT_DATE + INTERVAL '1 day',
 '09:00:00',
 150.00,
 'pending',
 'Airport transfer for 2 passengers with luggage',
 'TEST001'),

-- Another pending booking
('cccccccc-cccc-cccc-cccc-cccccccccccc',
 '22222222-2222-2222-2222-222222222222',
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
 'Windhoek Central',
 'Swakopmund Beach',
 4,
 CURRENT_DATE + INTERVAL '2 days',
 '08:00:00',
 300.00,
 'pending',
 'Family trip to the beach, 4 passengers',
 'TEST002'),

-- Confirmed booking assigned to a specific runner
('dddddddd-dddd-dddd-dddd-dddddddddddd',
 '11111111-1111-1111-1111-111111111111',
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
 'Windhoek Suburbs',
 'Windhoek Airport',
 1,
 CURRENT_DATE,
 '14:00:00',
 120.00,
 'confirmed',
 'Single passenger airport transfer',
 'TEST003')
ON CONFLICT (id) DO NOTHING;

-- Assign the confirmed booking to a runner
UPDATE transportation_bookings 
SET driver_id = '33333333-3333-3333-3333-333333333333'
WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

-- Create a completed booking for testing
INSERT INTO transportation_bookings (
    id,
    user_id, 
    service_id, 
    pickup_location, 
    dropoff_location,
    passenger_count, 
    booking_date, 
    booking_time, 
    final_price,
    status, 
    driver_id,
    special_requests,
    booking_reference
) VALUES
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
 '22222222-2222-2222-2222-222222222222',
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
 'Windhoek Central',
 'Katutura',
 1,
 CURRENT_DATE - INTERVAL '1 day',
 '10:00:00',
 80.00,
 'completed',
 '33333333-3333-3333-3333-333333333333',
 'Local city transfer',
 'TEST004')
ON CONFLICT (id) DO NOTHING;

-- Verify the data was created
SELECT 
    'transportation_bookings' as table_name, 
    COUNT(*) as total_count,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_count,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count
FROM transportation_bookings;

-- Show sample bookings
SELECT 
    id,
    status,
    pickup_location,
    dropoff_location,
    passenger_count,
    booking_date,
    booking_time,
    estimated_price,
    driver_id
FROM transportation_bookings
ORDER BY created_at DESC;
