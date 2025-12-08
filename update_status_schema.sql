-- Update errand status constraint to include 'pending'
-- This migration adds 'pending' as a valid status value for errands

-- First drop the existing constraint
ALTER TABLE errands DROP CONSTRAINT IF EXISTS errands_status_check;

-- Add the new constraint with 'pending' included
ALTER TABLE errands ADD CONSTRAINT errands_status_check 
CHECK (status IN ('posted', 'accepted', 'in_progress', 'pending', 'completed', 'cancelled'));

-- Update any existing 'in_progress' errands to 'pending' if desired
-- Uncomment the line below if you want to convert existing in_progress errands to pending
-- UPDATE errands SET status = 'pending' WHERE status = 'in_progress'; 