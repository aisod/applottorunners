-- Fix for Runner Notification Issue
-- This addresses the problem where transportation bookings can't find runners with matching vehicle types

-- 1. Add SUV vehicle type if it doesn't exist (to match what the booking system expects)
INSERT INTO vehicle_types (name, capacity, description, features, icon) VALUES
('SUV', 5, 'Sport Utility Vehicle for comfortable rides', ARRAY['AC', 'Radio', 'GPS', '4x4'], 'directions_car')
ON CONFLICT (name) DO NOTHING;

-- 2. Add more vehicle types that might be commonly used
INSERT INTO vehicle_types (name, capacity, description, features, icon) VALUES
('Hatchback', 5, 'Compact and economical vehicle', ARRAY['AC', 'Radio'], 'directions_car'),
('Pickup Truck', 5, 'Utility vehicle with cargo space', ARRAY['AC', 'Radio', 'Cargo Bed'], 'local_shipping'),
('Van', 12, 'Medium-sized van for groups', ARRAY['AC', 'Radio', 'GPS', 'Sliding Doors'], 'airport_shuttle')
ON CONFLICT (name) DO NOTHING;

-- 3. Create sample approved runners with different vehicle types
-- First, let's create some test users if they don't exist
INSERT INTO users (id, email, full_name, phone, user_type, is_verified, has_vehicle) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'john.doe@example.com', 'John Doe', '+264 81 123 4567', 'runner', true, true),
('550e8400-e29b-41d4-a716-446655440002', 'jane.smith@example.com', 'Jane Smith', '+264 81 234 5678', 'runner', true, true),
('550e8400-e29b-41d4-a716-446655440003', 'mike.johnson@example.com', 'Mike Johnson', '+264 81 345 6789', 'runner', true, true),
('550e8400-e29b-41d4-a716-446655440004', 'sarah.wilson@example.com', 'Sarah Wilson', '+264 81 456 7890', 'runner', true, true)
ON CONFLICT (id) DO NOTHING;

-- 4. Create runner applications with approved status for different vehicle types
INSERT INTO runner_applications (user_id, has_vehicle, vehicle_type, vehicle_details, license_number, verification_status, notes) VALUES
('550e8400-e29b-41d4-a716-446655440001', true, 'SUV', 'Toyota Fortuner 2020', 'NA123456', 'approved', 'Experienced driver with good ratings'),
('550e8400-e29b-41d4-a716-446655440002', true, 'Sedan', 'Toyota Corolla 2019', 'NA234567', 'approved', 'Reliable and punctual'),
('550e8400-e29b-41d4-a716-446655440003', true, 'Minivan', 'Toyota Hiace 2018', 'NA345678', 'approved', 'Great for family transport'),
('550e8400-e29b-41d4-a716-446655440004', true, 'Pickup Truck', 'Ford Ranger 2021', 'NA456789', 'approved', 'Good for cargo and passengers')
ON CONFLICT (user_id) DO NOTHING;

-- 5. Verify the setup
SELECT 'Vehicle Types' as info, COUNT(*) as count FROM vehicle_types
UNION ALL
SELECT 'Approved Runners', COUNT(*) FROM runner_applications WHERE verification_status = 'approved'
UNION ALL
SELECT 'Users with Runners', COUNT(DISTINCT user_id) FROM runner_applications WHERE verification_status = 'approved';

-- 6. Show the approved runners with their vehicle types
SELECT ra.user_id, u.full_name, ra.vehicle_type, ra.verification_status
FROM runner_applications ra
LEFT JOIN users u ON ra.user_id = u.id
WHERE ra.verification_status = 'approved'
ORDER BY ra.vehicle_type;
