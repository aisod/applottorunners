-- Add provider_names array to transportation_services table
-- This will store provider names directly in the services table for faster access

-- Add the provider_names column
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS provider_names TEXT[] DEFAULT '{}';

-- Create an index for better performance
CREATE INDEX IF NOT EXISTS idx_transportation_services_provider_names 
ON transportation_services USING GIN(provider_names);

-- Update existing services to populate provider_names from service_providers table
UPDATE transportation_services 
SET provider_names = (
  SELECT ARRAY_AGG(sp.name ORDER BY sp.name)
  FROM service_providers sp
  WHERE sp.id = ANY(transportation_services.provider_ids)
)
WHERE provider_ids IS NOT NULL 
AND array_length(provider_ids, 1) > 0;

-- Add comment to document the new column
COMMENT ON COLUMN transportation_services.provider_names IS 'Array of provider names, corresponding to provider_ids by index';

-- Create a function to automatically update provider_names when providers are added/removed
CREATE OR REPLACE FUNCTION update_provider_names()
RETURNS TRIGGER AS $$
BEGIN
  -- Update provider_names when provider_ids changes
  IF TG_OP = 'UPDATE' THEN
    NEW.provider_names = (
      SELECT ARRAY_AGG(sp.name ORDER BY sp.name)
      FROM service_providers sp
      WHERE sp.id = ANY(NEW.provider_ids)
    );
  ELSIF TG_OP = 'INSERT' THEN
    NEW.provider_names = (
      SELECT ARRAY_AGG(sp.name ORDER BY sp.name)
      FROM service_providers sp
      WHERE sp.id = ANY(NEW.provider_ids)
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update provider_names
DROP TRIGGER IF EXISTS trigger_update_provider_names ON transportation_services;
CREATE TRIGGER trigger_update_provider_names
  BEFORE INSERT OR UPDATE ON transportation_services
  FOR EACH ROW
  EXECUTE FUNCTION update_provider_names();

-- Verify the changes
SELECT 
    id,
    name,
    provider_ids,
    provider_names,
    array_length(provider_ids, 1) as provider_count,
    array_length(provider_names, 1) as name_count
FROM transportation_services 
ORDER BY name;
