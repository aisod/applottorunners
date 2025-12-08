-- Remove registration category from database
-- This script removes all registration-related data and constraints

-- 1. Remove registration services from services table
DELETE FROM services WHERE category = 'registration';

-- 2. Remove registration category from service_categories table
DELETE FROM service_categories WHERE name = 'registration';

-- 3. Update errands table constraint to remove 'registration' category
ALTER TABLE errands DROP CONSTRAINT IF EXISTS errands_category_check;
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
    'other'
));

-- 4. Remove any existing errands with registration category
DELETE FROM errands WHERE category = 'registration';

-- 5. Update any references in other tables that might reference registration
-- (This is a precautionary step in case there are foreign key references)

-- 6. Clean up any orphaned data
-- Remove any notifications related to registration errands
DELETE FROM notifications 
WHERE errand_id IN (
    SELECT id FROM errands WHERE category = 'registration'
);

-- Remove any chat messages related to registration errands  
DELETE FROM chat_messages 
WHERE errand_id IN (
    SELECT id FROM errands WHERE category = 'registration'
);

-- Remove any transportation bookings related to registration errands
DELETE FROM transportation_bookings 
WHERE errand_id IN (
    SELECT id FROM errands WHERE category = 'registration'
);

-- Remove any contract bookings related to registration errands
DELETE FROM contract_bookings 
WHERE errand_id IN (
    SELECT id FROM errands WHERE category = 'registration'
);

-- 7. Verify the changes
SELECT 'Services with registration category:' as check_type, COUNT(*) as count FROM services WHERE category = 'registration'
UNION ALL
SELECT 'Service categories with registration:' as check_type, COUNT(*) as count FROM service_categories WHERE name = 'registration'
UNION ALL
SELECT 'Errands with registration category:' as check_type, COUNT(*) as count FROM errands WHERE category = 'registration';

-- 8. Show remaining valid categories
SELECT 'Remaining service categories:' as info, name FROM service_categories ORDER BY name;


