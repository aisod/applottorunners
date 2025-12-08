-- Backfill service_type for old delivery records
-- This populates the service_type field from vehicle_type for existing delivery errands

-- Update delivery errands that have vehicle_type but no service_type
UPDATE errands
SET service_type = vehicle_type
WHERE category = 'delivery'
  AND vehicle_type IS NOT NULL
  AND (service_type IS NULL OR service_type = '');

-- Update pricing_modifiers to include service_type for old records
UPDATE errands
SET pricing_modifiers = jsonb_set(
  COALESCE(pricing_modifiers, '{}'::jsonb),
  '{service_type}',
  to_jsonb(vehicle_type)
)
WHERE category = 'delivery'
  AND vehicle_type IS NOT NULL
  AND (pricing_modifiers IS NULL OR NOT pricing_modifiers ? 'service_type');

-- Verify the updates
SELECT 
  id,
  category,
  vehicle_type,
  service_type,
  pricing_modifiers->>'service_type' as pm_service_type,
  price_amount
FROM errands
WHERE category = 'delivery'
  AND vehicle_type IS NOT NULL
LIMIT 10;

