-- Fix errand category constraint to allow all service categories
-- This resolves the "errands_category_check" constraint violation error

-- First, drop the existing constraint
ALTER TABLE errands DROP CONSTRAINT IF EXISTS errands_category_check;

-- Add the new constraint that allows all service categories
ALTER TABLE errands ADD CONSTRAINT errands_category_check 
CHECK (category IN (
    'grocery', 
    'delivery', 
    'document', 
    'shopping', 
    'cleaning',
    'maintenance',
    'other'
));

-- Add comment to document the change
COMMENT ON CONSTRAINT errands_category_check ON errands IS 
'Updated to allow all service categories including cleaning and maintenance';

-- Verify the constraint is working by checking current categories
SELECT DISTINCT category FROM services WHERE is_active = true;xl

-- Show the new constraint
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'errands'::regclass 
AND conname = 'errands_category_check';
