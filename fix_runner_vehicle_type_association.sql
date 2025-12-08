-- Fix Runner Vehicle Type Association
-- This migration ensures that runner vehicle types properly reference the vehicle_types table

-- 1. First, let's check what vehicle types exist in the vehicle_types table
SELECT id, name FROM vehicle_types ORDER BY name;

-- 2. Update the runner_applications table to use vehicle_type_id instead of vehicle_type text
-- Add vehicle_type_id column if it doesn't exist
ALTER TABLE runner_applications 
ADD COLUMN IF NOT EXISTS vehicle_type_id UUID REFERENCES vehicle_types(id);

-- 3. Create a mapping function to convert text vehicle types to UUIDs
CREATE OR REPLACE FUNCTION map_vehicle_type_to_id(vehicle_type_text TEXT)
RETURNS UUID AS $$
DECLARE
    vehicle_id UUID;
BEGIN
    -- Map common vehicle type names to vehicle_types table
    SELECT id INTO vehicle_id
    FROM vehicle_types
    WHERE LOWER(name) = LOWER(vehicle_type_text)
    LIMIT 1;
    
    RETURN vehicle_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Update existing runner applications to use vehicle_type_id
-- This will map existing text vehicle types to the corresponding vehicle_type_id
UPDATE runner_applications 
SET vehicle_type_id = map_vehicle_type_to_id(vehicle_type)
WHERE vehicle_type IS NOT NULL 
AND vehicle_type_id IS NULL;

-- 5. Add a constraint to ensure vehicle_type_id is set when has_vehicle is true
ALTER TABLE runner_applications 
ADD CONSTRAINT check_vehicle_type_when_has_vehicle 
CHECK (
    (has_vehicle = false AND vehicle_type_id IS NULL) OR
    (has_vehicle = true AND vehicle_type_id IS NOT NULL)
);

-- 6. Create an index for better performance
CREATE INDEX IF NOT EXISTS idx_runner_applications_vehicle_type_id 
ON runner_applications(vehicle_type_id);

-- 7. Add a comment to document the change
COMMENT ON COLUMN runner_applications.vehicle_type_id IS 'Reference to vehicle_types table for proper vehicle type association';

-- 8. Show the results of the migration
SELECT 
    ra.user_id,
    ra.has_vehicle,
    ra.vehicle_type as old_vehicle_type,
    ra.vehicle_type_id,
    vt.name as new_vehicle_type_name
FROM runner_applications ra
LEFT JOIN vehicle_types vt ON ra.vehicle_type_id = vt.id
WHERE ra.has_vehicle = true
ORDER BY ra.applied_at DESC;

-- 9. Clean up the mapping function
DROP FUNCTION IF EXISTS map_vehicle_type_to_id(TEXT);
