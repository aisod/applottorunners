-- Update errands_service_type_check constraint to allow more document service types
-- This allows the document services form to use more service types

-- First, drop the existing constraint
ALTER TABLE errands DROP CONSTRAINT IF EXISTS errands_service_type_check;

-- Add the new constraint with expanded service types for document_services
ALTER TABLE errands ADD CONSTRAINT errands_service_type_check 
CHECK (
    (category != 'document_services') OR 
    (category = 'document_services' AND service_type IN (
        'certify', 
        'copies', 
        'printing',
        'scanning',
        'photocopying',
        'binding',
        'laminating',
        'copies & certify',
        'other'
    ))
);

-- Add comment to document the change
COMMENT ON CONSTRAINT errands_service_type_check ON errands IS 
'Updated to allow more document service types including printing, scanning, photocopying, binding, laminating, and copies & certify';

-- Verify the constraint is working
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'errands'::regclass 
AND conname = 'errands_service_type_check';
