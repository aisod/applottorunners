-- Fix the missing accepted_at column in transportation_bookings table

-- Add accepted_at column if it doesn't exist
ALTER TABLE transportation_bookings 
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE;

-- Add started_at column if it doesn't exist (for workflow tracking)
ALTER TABLE transportation_bookings 
ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE;

-- Add completed_at column if it doesn't exist (for workflow tracking)
ALTER TABLE transportation_bookings 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Add cancelled_at column if it doesn't exist (for workflow tracking)
ALTER TABLE transportation_bookings 
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

-- Add cancellation_reason column if it doesn't exist
ALTER TABLE transportation_bookings 
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- Update existing accepted bookings to have accepted_at timestamp
UPDATE transportation_bookings 
SET accepted_at = created_at 
WHERE status = 'accepted' AND accepted_at IS NULL;

-- Verify the columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'transportation_bookings' 
  AND column_name IN ('accepted_at', 'started_at', 'completed_at', 'cancelled_at', 'cancellation_reason')
ORDER BY column_name;
