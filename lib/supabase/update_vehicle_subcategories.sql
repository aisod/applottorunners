-- Update vehicle types to properly associate them with service subcategories
-- This ensures that when a user selects a subcategory, only relevant vehicles are shown

-- First, let's check what subcategories exist
SELECT id, name FROM service_subcategories ORDER BY sort_order;

-- Now let's update vehicle types to associate them with the correct subcategories
-- Based on the vehicle types and their intended use:

-- 1. Bus Services subcategory (ID: 1) - for scheduled bus routes
UPDATE vehicle_types 
SET service_subcategory_ids = ARRAY[(SELECT id FROM service_subcategories WHERE name = 'Bus Services')]
WHERE name IN ('Minibus', 'Bus');

-- 2. Shuttle Services subcategory (ID: 2) - for door-to-door shuttle services
UPDATE vehicle_types 
SET service_subcategory_ids = ARRAY[(SELECT id FROM service_subcategories WHERE name = 'Shuttle Services')]
WHERE name IN ('Sedan', 'Hatchback', 'Minivan');

-- 3. Contract Subscription subcategory - for long-term business contracts
UPDATE vehicle_types 
SET service_subcategory_ids = ARRAY[(SELECT id FROM service_subcategories WHERE name = 'Contract Subscription')]
WHERE name IN ('Large Van', 'Minibus', 'Cargo Van');

-- 4. Ride Sharing subcategory (ID: 4) - for individual and group ride sharing
UPDATE vehicle_types 
SET service_subcategory_ids = ARRAY[(SELECT id FROM service_subcategories WHERE name = 'Ride Sharing')]
WHERE name IN ('Sedan', 'Hatchback');

-- 4. Airport Transfers subcategory (ID: 4) - for airport pickup and drop-off
UPDATE vehicle_types 
SET service_subcategory_ids = ARRAY[(SELECT id FROM service_subcategories WHERE name = 'Airport Transfers')]
WHERE name IN ('Sedan', 'Hatchback', 'Minivan', 'Large Van');

-- 5. Cargo Transport subcategory (ID: 5) - for commercial cargo transportation
UPDATE vehicle_types 
SET service_subcategory_ids = ARRAY[(SELECT id FROM service_subcategories WHERE name = 'Cargo Transport')]
WHERE name IN ('Pickup Truck', 'Cargo Van', 'Large Van');

-- 6. Moving Services subcategory (ID: 6) - for household and office moving
UPDATE vehicle_types 
SET service_subcategory_ids = ARRAY[(SELECT id FROM service_subcategories WHERE name = 'Moving Services')]
WHERE name IN ('Large Van', 'Cargo Van', 'Pickup Truck');

-- Verify the updates
SELECT 
    vt.name as vehicle_name,
    vt.service_subcategory_ids,
    array_agg(ss.name) as subcategory_names
FROM vehicle_types vt
LEFT JOIN service_subcategories ss ON ss.id = ANY(vt.service_subcategory_ids)
GROUP BY vt.name, vt.service_subcategory_ids
ORDER BY vt.name;
