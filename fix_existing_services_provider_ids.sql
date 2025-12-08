-- Fix existing transportation services that have null or empty provider_ids
-- Set provider_ids to empty array if it's null
UPDATE transportation_services 
SET provider_ids = '{}'::UUID[]
WHERE provider_ids IS NULL;

-- Set other array fields to empty arrays if they're null
UPDATE transportation_services 
SET 
    prices = '{}'::DECIMAL[],
    departure_times = '{}'::TEXT[],
    check_in_times = '{}'::TEXT[],
    provider_operating_days = '{}'::INTEGER[][],
    advance_booking_hours_array = '{}'::INTEGER[],
    cancellation_hours_array = '{}'::INTEGER[]
WHERE 
    prices IS NULL OR 
    departure_times IS NULL OR 
    check_in_times IS NULL OR 
    provider_operating_days IS NULL OR 
    advance_booking_hours_array IS NULL OR 
    cancellation_hours_array IS NULL;

-- Verify the fix
SELECT 
    id,
    name,
    provider_ids,
    array_length(provider_ids, 1) as provider_count,
    array_length(prices, 1) as price_count,
    array_length(departure_times, 1) as departure_count
FROM transportation_services 
ORDER BY name;
