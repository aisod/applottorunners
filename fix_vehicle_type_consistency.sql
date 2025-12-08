-- Fix Vehicle Type Consistency
-- This script ensures vehicle type names are consistent between tables

-- 1. First, let's see what we're working with
SELECT 'Current vehicle_types table:' as info;
SELECT id, name FROM vehicle_types ORDER BY name;

SELECT 'Current runner_applications vehicle types:' as info;
SELECT DISTINCT vehicle_type, COUNT(*) as count 
FROM runner_applications 
WHERE verification_status = 'approved'
GROUP BY vehicle_type 
ORDER BY vehicle_type;

-- 2. Create a mapping table to standardize vehicle type names
CREATE TABLE IF NOT EXISTS vehicle_type_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_name TEXT NOT NULL,
    standardized_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Insert common vehicle type mappings
INSERT INTO vehicle_type_mapping (original_name, standardized_name) VALUES
    ('SUV', 'SUV'),
    ('suv', 'SUV'),
    ('Suv', 'SUV'),
    ('Sedan', 'Sedan'),
    ('sedan', 'Sedan'),
    ('SEDAN', 'Sedan'),
    ('Motorcycle', 'Motorcycle'),
    ('motorcycle', 'Motorcycle'),
    ('MOTORCYCLE', 'Motorcycle'),
    ('Bike', 'Bike'),
    ('bike', 'Bike'),
    ('BIKE', 'Bike'),
    ('Van', 'Van'),
    ('van', 'Van'),
    ('VAN', 'Van'),
    ('Minibus', 'Minibus'),
    ('minibus', 'Minibus'),
    ('MINIBUS', 'Minibus'),
    ('Bus', 'Bus'),
    ('bus', 'Bus'),
    ('BUS', 'Bus'),
    ('Truck', 'Truck'),
    ('truck', 'Truck'),
    ('TRUCK', 'Truck'),
    ('Pickup', 'Pickup'),
    ('pickup', 'Pickup'),
    ('PICKUP', 'Pickup'),
    ('Cargo Van', 'Cargo Van'),
    ('cargo van', 'Cargo Van'),
    ('CARGO VAN', 'Cargo Van'),
    ('Large Van', 'Large Van'),
    ('large van', 'Large Van'),
    ('LARGE VAN', 'Large Van')
ON CONFLICT (original_name) DO NOTHING;

-- 4. Update runner_applications to use standardized vehicle type names
UPDATE runner_applications 
SET vehicle_type = vtm.standardized_name
FROM vehicle_type_mapping vtm
WHERE LOWER(runner_applications.vehicle_type) = LOWER(vtm.original_name)
    AND runner_applications.verification_status = 'approved';

-- 5. Update vehicle_types table to use standardized names
UPDATE vehicle_types 
SET name = vtm.standardized_name
FROM vehicle_type_mapping vtm
WHERE LOWER(vehicle_types.name) = LOWER(vtm.original_name);

-- 6. Show the results after standardization
SELECT 'After standardization - vehicle_types:' as info;
SELECT id, name FROM vehicle_types ORDER BY name;

SELECT 'After standardization - runner_applications:' as info;
SELECT DISTINCT vehicle_type, COUNT(*) as count 
FROM runner_applications 
WHERE verification_status = 'approved'
GROUP BY vehicle_type 
ORDER BY vehicle_type;

-- 7. Test the matching logic
SELECT 'Testing matching logic:' as info;
SELECT 
    vt.name as vehicle_types_name,
    ra.vehicle_type as runner_applications_vehicle_type,
    CASE 
        WHEN vt.name = ra.vehicle_type THEN 'EXACT MATCH'
        WHEN LOWER(vt.name) = LOWER(ra.vehicle_type) THEN 'CASE INSENSITIVE MATCH'
        ELSE 'NO MATCH'
    END as match_status,
    COUNT(*) as count
FROM vehicle_types vt
CROSS JOIN runner_applications ra
WHERE ra.verification_status = 'approved'
GROUP BY vt.name, ra.vehicle_type, match_status
ORDER BY match_status, vt.name;

-- 8. Show runners that should receive notifications for each vehicle type
SELECT 'Runners by vehicle type:' as info;
SELECT 
    vt.name as vehicle_type,
    COUNT(ra.user_id) as runner_count,
    STRING_AGG(u.full_name, ', ') as runner_names
FROM vehicle_types vt
LEFT JOIN runner_applications ra ON LOWER(vt.name) = LOWER(ra.vehicle_type)
LEFT JOIN users u ON ra.user_id = u.id
WHERE ra.verification_status = 'approved' OR ra.verification_status IS NULL
GROUP BY vt.name
ORDER BY vt.name;
