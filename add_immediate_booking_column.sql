-- Add is_immediate column to transportation_bookings table
-- This column will help identify immediate ride requests vs scheduled bookings

-- Add the column
ALTER TABLE transportation_bookings 
ADD COLUMN IF NOT EXISTS is_immediate BOOLEAN DEFAULT false;

-- Add a comment to document the column
COMMENT ON COLUMN transportation_bookings.is_immediate IS 'Flag to indicate if this is an immediate booking (Request Now) vs scheduled booking';

-- Create an index for better performance when filtering immediate bookings
CREATE INDEX IF NOT EXISTS idx_transportation_bookings_is_immediate 
ON transportation_bookings(is_immediate);

-- Update existing records to set is_immediate based on booking_date and booking_time
-- If both are null, it's likely an immediate booking
UPDATE transportation_bookings 
SET is_immediate = true 
WHERE booking_date IS NULL AND booking_time IS NULL;

-- Show the results
SELECT 
    id,
    pickup_location,
    dropoff_location,
    booking_date,
    booking_time,
    is_immediate,
    created_at
FROM transportation_bookings 
ORDER BY created_at DESC 
LIMIT 10;
