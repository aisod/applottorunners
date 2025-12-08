-- Debug Vehicle Type Matching
-- This script helps identify why runners aren't being found for vehicle type matching

-- 1. Check what vehicle types exist in vehicle_types table
SELECT 
    id,
    name,
    LOWER(name) as lowercase_name,
    UPPER(name) as uppercase_name
FROM vehicle_types 
ORDER BY name;

-- 2. Check what vehicle types exist in runner_applications table
SELECT 
    vehicle_type,
    LOWER(vehicle_type) as lowercase_vehicle_type,
    UPPER(vehicle_type) as uppercase_vehicle_type,
    COUNT(*) as runner_count
FROM runner_applications 
WHERE verification_status = 'approved'
GROUP BY vehicle_type
ORDER BY vehicle_type;

-- 3. Check specific vehicle type matching (replace 'SUV' with the actual vehicle type)
SELECT 
    'vehicle_types' as table_name,
    name as vehicle_type_name,
    LOWER(name) as lowercase_name
FROM vehicle_types 
WHERE LOWER(name) LIKE '%suv%'
UNION ALL
SELECT 
    'runner_applications' as table_name,
    vehicle_type as vehicle_type_name,
    LOWER(vehicle_type) as lowercase_name
FROM runner_applications 
WHERE verification_status = 'approved' 
    AND LOWER(vehicle_type) LIKE '%suv%';

-- 4. Show all approved runners with their vehicle types
SELECT 
    ra.user_id,
    ra.vehicle_type,
    LOWER(ra.vehicle_type) as lowercase_vehicle_type,
    u.full_name,
    ra.verification_status
FROM runner_applications ra
JOIN users u ON ra.user_id = u.id
WHERE ra.verification_status = 'approved'
ORDER BY ra.vehicle_type, u.full_name;

-- 5. Test the exact matching logic
-- Replace 'SUV' with the actual vehicle type from step 3
WITH test_vehicle_type AS (
    SELECT 'SUV' as test_name
)
SELECT 
    vt.name as vehicle_types_name,
    ra.vehicle_type as runner_applications_vehicle_type,
    CASE 
        WHEN vt.name = ra.vehicle_type THEN 'EXACT MATCH'
        WHEN LOWER(vt.name) = LOWER(ra.vehicle_type) THEN 'CASE INSENSITIVE MATCH'
        ELSE 'NO MATCH'
    END as match_status
FROM vehicle_types vt
CROSS JOIN test_vehicle_type tvt
CROSS JOIN runner_applications ra
WHERE ra.verification_status = 'approved'
    AND (vt.name = tvt.test_name OR ra.vehicle_type = tvt.test_name)
ORDER BY match_status;
