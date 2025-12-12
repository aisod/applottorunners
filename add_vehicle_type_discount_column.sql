-- Add discount_percentage column to vehicle_types table
-- Run this script in your Supabase SQL Editor to fix the missing column error

-- Add discount_percentage to vehicle_types table (for rides)
ALTER TABLE vehicle_types 
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Add comment to explain the column
COMMENT ON COLUMN vehicle_types.discount_percentage IS 'Percentage discount to apply to this vehicle type (0-100)';

-- Create index for faster queries on discounted items
CREATE INDEX IF NOT EXISTS idx_vehicle_types_discount ON vehicle_types(discount_percentage) WHERE discount_percentage > 0;

-- Update existing vehicle types to have 0 discount if null
UPDATE vehicle_types 
SET discount_percentage = 0.00 
WHERE discount_percentage IS NULL;

