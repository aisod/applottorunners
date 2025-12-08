-- Fix provider relationships for transportation_services table
-- First, let's check if we need to migrate existing data

-- Option 1: Update existing transportation_services to use the new providers table
-- This requires migrating existing service_providers data to the new providers table

-- First, let's see what's in the existing service_providers table
-- SELECT * FROM service_providers LIMIT 5;

-- If we want to migrate existing data, we can do this:
-- INSERT INTO providers (name, location, phone_number, is_active, created_at, updated_at)
-- SELECT 
--     name,
--     COALESCE(location, 'Unknown') as location,
--     COALESCE(contact_phone, 'Unknown') as phone_number,
--     is_active,
--     created_at,
--     updated_at
-- FROM service_providers
-- ON CONFLICT (name) DO NOTHING;

-- Then update transportation_services to reference the new providers table
-- ALTER TABLE transportation_services 
-- ADD COLUMN IF NOT EXISTS new_provider_id UUID REFERENCES providers(id);

-- Update the new_provider_id based on matching names
-- UPDATE transportation_services 
-- SET new_provider_id = p.id
-- FROM providers p
-- WHERE p.name = (
--     SELECT sp.name 
--     FROM service_providers sp 
--     WHERE sp.id = transportation_services.provider_id
-- );

-- For now, let's use a simpler approach - keep the existing structure but add the new fields
-- This avoids breaking existing data while adding the new functionality

-- Add the new fields to transportation_services if they don't exist
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS departure_time TIME,
ADD COLUMN IF NOT EXISTS check_in_time TIME,
ADD COLUMN IF NOT EXISTS days_of_week TEXT[] DEFAULT '{}';

-- Add comment to explain days_of_week format
COMMENT ON COLUMN transportation_services.days_of_week IS 'Array of days: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday';

-- For now, let's revert the Supabase queries to use service_providers instead of providers
-- This will allow the existing functionality to work while we add the new fields

-- The Flutter app should work with the existing service_providers table
-- and the new fields (price, departure_time, check_in_time, days_of_week)
