-- Check what's actually in the transportation_services table
-- This will help diagnose why provider data is not being retrieved

-- Step 1: Check the structure of the table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'transportation_services' 
ORDER BY ordinal_position;

-- Step 2: Check the actual data in the table
SELECT 
    id,
    name,
    provider_ids,
    prices,
    departure_times,
    check_in_times,
    provider_operating_days,
    advance_booking_hours_array,
    cancellation_hours_array,
    features_array,
    pg_typeof(provider_ids) as provider_ids_type,
    pg_typeof(prices) as prices_type,
    array_length(provider_ids, 1) as provider_count,
    array_length(prices, 1) as price_count
FROM transportation_services 
ORDER BY name;

-- Step 3: Check if there are any service_providers
SELECT 
    COUNT(*) as total_providers,
    COUNT(CASE WHEN name IS NOT NULL THEN 1 END) as providers_with_names
FROM service_providers;

-- Step 4: Show sample service_providers
SELECT 
    id,
    name,
    contact_phone,
    contact_email,
    created_at
FROM service_providers 
LIMIT 5;

-- Step 5: Check if there are any relationships between services and providers
SELECT 
    ts.name as service_name,
    ts.provider_ids,
    sp.name as provider_name,
    sp.id as provider_id
FROM transportation_services ts
LEFT JOIN service_providers sp ON sp.id = ANY(ts.provider_ids)
ORDER BY ts.name;
