-- Migration to drop service_schedules table and all related references
-- This removes the unused service_schedules table from the database

-- 1. Drop foreign key constraints that reference service_schedules
ALTER TABLE transportation_bookings 
DROP CONSTRAINT IF EXISTS transportation_bookings_schedule_id_fkey;

ALTER TABLE bus_service_bookings 
DROP CONSTRAINT IF EXISTS bus_service_bookings_schedule_id_fkey;

-- 2. Drop the schedule_id columns (optional - comment out if you want to keep the columns)
-- ALTER TABLE transportation_bookings DROP COLUMN IF EXISTS schedule_id;
-- ALTER TABLE bus_service_bookings DROP COLUMN IF EXISTS schedule_id;

-- 3. Drop indexes on service_schedules
DROP INDEX IF EXISTS idx_service_schedules_service;

-- 4. Drop triggers on service_schedules
DROP TRIGGER IF EXISTS update_service_schedules_updated_at ON service_schedules;

-- 5. Drop RLS policies on service_schedules
DROP POLICY IF EXISTS "Public can view active schedules" ON service_schedules;
DROP POLICY IF EXISTS "Admins can manage schedules" ON service_schedules;
DROP POLICY IF EXISTS "Admins can manage all schedules" ON service_schedules;

-- 6. Drop the service_schedules table
DROP TABLE IF EXISTS service_schedules CASCADE;

