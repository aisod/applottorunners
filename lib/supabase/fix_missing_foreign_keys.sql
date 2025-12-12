-- Migration to fix missing foreign key constraints in transportation_bookings table
-- This migration adds the missing foreign key relationships

-- 1. Add missing foreign key constraint for service_id
ALTER TABLE transportation_bookings 
ADD CONSTRAINT IF NOT EXISTS transportation_bookings_service_id_fkey 
FOREIGN KEY (service_id) REFERENCES transportation_services(id) ON DELETE SET NULL;


-- 3. Verify all foreign key constraints exist
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'transportation_bookings'
ORDER BY tc.constraint_name;

-- 4. Check if the tables exist and have the right structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('transportation_bookings', 'transportation_services')
ORDER BY table_name, ordinal_position;
