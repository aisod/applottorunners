-- Add location coordinate fields to errands table
-- This migration adds latitude and longitude fields for better location tracking

-- Add location coordinate columns
ALTER TABLE errands ADD COLUMN IF NOT EXISTS location_latitude DECIMAL(10,8);
ALTER TABLE errands ADD COLUMN IF NOT EXISTS location_longitude DECIMAL(11,8);
ALTER TABLE errands ADD COLUMN IF NOT EXISTS pickup_latitude DECIMAL(10,8);
ALTER TABLE errands ADD COLUMN IF NOT EXISTS pickup_longitude DECIMAL(11,8);
ALTER TABLE errands ADD COLUMN IF NOT EXISTS delivery_latitude DECIMAL(10,8);
ALTER TABLE errands ADD COLUMN IF NOT EXISTS delivery_longitude DECIMAL(11,8);

-- Add indexes for better performance on location queries
CREATE INDEX IF NOT EXISTS idx_errands_location_coords ON errands(location_latitude, location_longitude);
CREATE INDEX IF NOT EXISTS idx_errands_pickup_coords ON errands(pickup_latitude, pickup_longitude);
CREATE INDEX IF NOT EXISTS idx_errands_delivery_coords ON errands(delivery_latitude, delivery_longitude);

-- Add comment to document the new fields
COMMENT ON COLUMN errands.location_latitude IS 'Latitude of the main location address';
COMMENT ON COLUMN errands.location_longitude IS 'Longitude of the main location address';
COMMENT ON COLUMN errands.pickup_latitude IS 'Latitude of the pickup location (optional)';
COMMENT ON COLUMN errands.pickup_longitude IS 'Longitude of the pickup location (optional)';
COMMENT ON COLUMN errands.delivery_latitude IS 'Latitude of the delivery location (optional)';
COMMENT ON COLUMN errands.delivery_longitude IS 'Longitude of the delivery location (optional)';
