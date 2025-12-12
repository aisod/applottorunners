-- Add discount_percentage column to services table
-- Run this script in your Supabase SQL Editor to fix the missing column error

-- Add discount_percentage to services table (for errands)
ALTER TABLE services 
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Add comment to explain the column
COMMENT ON COLUMN services.discount_percentage IS 'Percentage discount to apply to this service (0-100)';

-- Create index for faster queries on discounted items
CREATE INDEX IF NOT EXISTS idx_services_discount ON services(discount_percentage) WHERE discount_percentage > 0;

-- Update existing services to have 0 discount if null
UPDATE services 
SET discount_percentage = 0.00 
WHERE discount_percentage IS NULL;

