-- Add selected_provider column to bus_service_bookings table
-- This allows storing which provider was selected for each booking

ALTER TABLE bus_service_bookings 
ADD COLUMN selected_provider TEXT;

-- Add a comment to document the column purpose
COMMENT ON COLUMN bus_service_bookings.selected_provider IS 'The name of the provider selected for this booking';

-- Update existing records to have a default value (optional)
UPDATE bus_service_bookings 
SET selected_provider = 'Unknown Provider' 
WHERE selected_provider IS NULL;

-- Make the column NOT NULL after setting default values (optional)
-- ALTER TABLE bus_service_bookings ALTER COLUMN selected_provider SET NOT NULL;

-- Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'bus_service_bookings' 
AND column_name = 'selected_provider';
