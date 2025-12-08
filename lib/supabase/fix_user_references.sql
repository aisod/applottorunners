-- Migration to fix user references in transportation tables
-- This migration updates foreign key references from auth.users to the users table

-- 1. Drop existing foreign key constraints
ALTER TABLE transportation_bookings DROP CONSTRAINT IF EXISTS transportation_bookings_user_id_fkey;
ALTER TABLE transportation_bookings DROP CONSTRAINT IF EXISTS transportation_bookings_driver_id_fkey;
ALTER TABLE service_reviews DROP CONSTRAINT IF EXISTS service_reviews_user_id_fkey;

-- 2. Add new foreign key constraints pointing to the users table
ALTER TABLE transportation_bookings ADD CONSTRAINT transportation_bookings_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE transportation_bookings ADD CONSTRAINT transportation_bookings_driver_id_fkey 
    FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE service_reviews ADD CONSTRAINT service_reviews_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- 3. Verify the changes
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
    AND tc.table_name IN ('transportation_bookings', 'service_reviews')
ORDER BY tc.table_name, tc.constraint_name;
