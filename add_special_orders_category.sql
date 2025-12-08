-- Add special_orders category to errands table constraint
-- This fixes the PostgrestException for special orders

-- Drop the existing category constraint
ALTER TABLE errands DROP CONSTRAINT IF EXISTS errands_category_check;

-- Add updated constraint that includes special_orders
ALTER TABLE errands ADD CONSTRAINT errands_category_check 
CHECK (category IN (
    'queue_sitting', 
    'license_discs', 
    'shopping', 
    'document_services', 
    'elderly_services',
    'grocery', 
    'delivery', 
    'document', 
    'cleaning', 
    'maintenance',
    'special_orders',  -- NEW: Added for custom special orders
    'transportation',  -- For ride services
    'other'
));

-- Add comment to document the constraint
COMMENT ON CONSTRAINT errands_category_check ON errands IS 
'Updated to include special_orders category for custom service requests and transportation for ride services';

-- Verify the constraint
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'errands'::regclass 
AND conname = 'errands_category_check';

-- Check current categories in use
SELECT DISTINCT category, COUNT(*) as count
FROM errands
GROUP BY category
ORDER BY count DESC;


