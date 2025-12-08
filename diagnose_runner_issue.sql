-- Diagnose the runner notification issue
-- Check available vehicle types
SELECT id, name FROM vehicle_types ORDER BY name;

-- Check what runners are registered
SELECT user_id, vehicle_type, verification_status FROM runner_applications;

-- Check recent transportation bookings
SELECT id, vehicle_type_id, pickup_location, dropoff_location, is_immediate, status
FROM transportation_bookings
ORDER BY created_at DESC
LIMIT 5;

-- Check if there are any approved runners with vehicle types
SELECT ra.user_id, ra.vehicle_type, ra.verification_status, vt.name as vehicle_type_name
FROM runner_applications ra
LEFT JOIN vehicle_types vt ON ra.vehicle_type = vt.name
WHERE ra.verification_status = 'approved';

-- Check the specific booking that was created
SELECT tb.*, vt.name as vehicle_type_name
FROM transportation_bookings tb
LEFT JOIN vehicle_types vt ON tb.vehicle_type_id = vt.id
WHERE tb.id = 'c5fb04cf-2725-4637-959f-5990063a5521';

-- Check if 'SUV' vehicle type exists (the one from the error)
SELECT * FROM vehicle_types WHERE name = 'SUV';

-- Check all approved runners and their vehicle types
SELECT ra.*, u.full_name, u.email
FROM runner_applications ra
LEFT JOIN users u ON ra.user_id = u.id
WHERE ra.verification_status = 'approved';

-- Check if any runner has 'SUV' as their vehicle type
SELECT * FROM runner_applications WHERE vehicle_type = 'SUV';
