-- Add discount percentage columns to services and vehicle_types tables
-- This allows admins to apply percentage discounts to services and rides

-- Add discount_percentage to services table (for errands)
ALTER TABLE services 
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Add discount_percentage to vehicle_types table (for rides)
ALTER TABLE vehicle_types 
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Add comment to explain the column
COMMENT ON COLUMN services.discount_percentage IS 'Percentage discount to apply to this service (0-100)';
COMMENT ON COLUMN vehicle_types.discount_percentage IS 'Percentage discount to apply to this vehicle type (0-100)';

-- Create index for faster queries on discounted items
CREATE INDEX IF NOT EXISTS idx_services_discount ON services(discount_percentage) WHERE discount_percentage > 0;
CREATE INDEX IF NOT EXISTS idx_vehicle_types_discount ON vehicle_types(discount_percentage) WHERE discount_percentage > 0;

