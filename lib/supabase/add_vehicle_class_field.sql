-- Add vehicle_class field to vehicle_types table
-- This field will allow users to select between standard, premium, and economic vehicle types

-- 1. Add the vehicle_class column
ALTER TABLE vehicle_types 
ADD COLUMN IF NOT EXISTS vehicle_class VARCHAR(20) DEFAULT 'standard' 
CHECK (vehicle_class IN ('standard', 'premium', 'economic'));

-- 2. Update existing vehicle types with appropriate classes
UPDATE vehicle_types 
SET vehicle_class = 'economic' 
WHERE name IN ('Sedan', 'Hatchback', 'Pickup Truck');

UPDATE vehicle_types 
SET vehicle_class = 'standard' 
WHERE name IN ('Minivan', 'Large Van', 'Cargo Van');

UPDATE vehicle_types 
SET vehicle_class = 'premium' 
WHERE name IN ('Minibus', 'Bus');

-- 3. Create an index for better performance on vehicle_class queries
CREATE INDEX IF NOT EXISTS idx_vehicle_types_class ON vehicle_types(vehicle_class);

-- 4. Add a comment to document the field
COMMENT ON COLUMN vehicle_types.vehicle_class IS 'Vehicle class: standard, premium, or economic for pricing and categorization';
