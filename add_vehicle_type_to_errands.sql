-- Add vehicle_type column to errands table
-- This allows storing the preferred vehicle type for each errand

ALTER TABLE errands 
ADD COLUMN IF NOT EXISTS vehicle_type TEXT CHECK (vehicle_type IN ('car', 'motorcycle', 'bicycle', 'van', 'truck'));

-- Create index for vehicle_type for better query performance
CREATE INDEX IF NOT EXISTS idx_errands_vehicle_type ON errands(vehicle_type);

-- Add comment to document the column
COMMENT ON COLUMN errands.vehicle_type IS 'Preferred vehicle type for this errand: car, motorcycle, bicycle, van, or truck';
