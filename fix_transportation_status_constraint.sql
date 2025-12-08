-- Fix transportation bookings status constraint to include 'in_progress'
-- This migration adds 'in_progress' as a valid status value for transportation bookings

-- First drop the existing constraint
ALTER TABLE transportation_bookings DROP CONSTRAINT IF EXISTS transportation_bookings_status_check;

-- Add the new constraint with 'in_progress' included
ALTER TABLE transportation_bookings ADD CONSTRAINT transportation_bookings_status_check 
CHECK (status IN ('pending', 'confirmed', 'in_progress', 'cancelled', 'completed', 'no_show')); 