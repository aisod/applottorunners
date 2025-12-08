-- Quick Fix for vehicle_class constraint issue
-- Run this immediately to fix the current error

-- 1. Make vehicle_class nullable (if it exists)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vehicle_types' 
        AND column_name = 'vehicle_class'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE vehicle_types ALTER COLUMN vehicle_class DROP NOT NULL;
        RAISE NOTICE 'Made vehicle_class column nullable';
    ELSE
        RAISE NOTICE 'vehicle_class column is already nullable or does not exist';
    END IF;
END $$;

-- 2. Add service_subcategory_ids column if it doesn't exist
ALTER TABLE vehicle_types 
ADD COLUMN IF NOT EXISTS service_subcategory_ids UUID[] DEFAULT '{}';

-- 3. Verify the fix
SELECT 
    column_name, 
    is_nullable, 
    data_type
FROM information_schema.columns 
WHERE table_name = 'vehicle_types' 
AND column_name IN ('vehicle_class', 'service_subcategory_ids')
ORDER BY column_name;
