-- Migration to remove category_id from service_subcategories table
-- This migration removes the foreign key relationship between service_subcategories and service_categories

-- 1. Drop the foreign key constraint
ALTER TABLE service_subcategories DROP CONSTRAINT IF EXISTS service_subcategories_category_id_fkey;

-- 2. Drop the unique constraint that includes category_id
ALTER TABLE service_subcategories DROP CONSTRAINT IF EXISTS service_subcategories_category_id_name_key;

-- 3. Drop the index that includes category_id
DROP INDEX IF EXISTS idx_service_subcategories_category;

-- 4. Remove the category_id column
ALTER TABLE service_subcategories DROP COLUMN IF EXISTS category_id;

-- 5. Add a new unique constraint on just the name
ALTER TABLE service_subcategories ADD CONSTRAINT service_subcategories_name_key UNIQUE (name);

-- 6. Create a new index for active subcategories
CREATE INDEX IF NOT EXISTS idx_service_subcategories_active ON service_subcategories(is_active);

-- 7. Update any existing data to ensure names are unique
-- This will remove duplicates if they exist
DELETE FROM service_subcategories a USING service_subcategories b 
WHERE a.id > b.id AND a.name = b.name;

-- 8. Verify the changes
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'service_subcategories' 
ORDER BY ordinal_position;
