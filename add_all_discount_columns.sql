-- Add discount_percentage columns to both services and vehicle_types tables
-- Run this script in your Supabase SQL Editor to fix the missing column errors

-- Add discount_percentage to services table (for errands)
ALTER TABLE services 
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Add discount_percentage to vehicle_types table (for rides)
ALTER TABLE vehicle_types 
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Add comments to explain the columns
COMMENT ON COLUMN services.discount_percentage IS 'Percentage discount to apply to this service (0-100)';
COMMENT ON COLUMN vehicle_types.discount_percentage IS 'Percentage discount to apply to this vehicle type (0-100)';

-- Create indexes for faster queries on discounted items
CREATE INDEX IF NOT EXISTS idx_services_discount ON services(discount_percentage) WHERE discount_percentage > 0;
CREATE INDEX IF NOT EXISTS idx_vehicle_types_discount ON vehicle_types(discount_percentage) WHERE discount_percentage > 0;

-- Update existing records to have 0 discount if null
UPDATE services 
SET discount_percentage = 0.00 
WHERE discount_percentage IS NULL;

UPDATE vehicle_types 
SET discount_percentage = 0.00 
WHERE discount_percentage IS NULL;

