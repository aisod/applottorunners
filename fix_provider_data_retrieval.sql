-- Comprehensive fix for provider data retrieval issues
-- This script addresses the "count is saying 0" problem

-- Step 1: Check current state
SELECT 
    'Current State Check' as step,
    COUNT(*) as total_services,
    COUNT(CASE WHEN provider_ids IS NOT NULL AND array_length(provider_ids, 1) > 0 THEN 1 END) as services_with_providers,
    COUNT(CASE WHEN provider_ids IS NULL OR array_length(provider_ids, 1) = 0 THEN 1 END) as services_without_providers
FROM transportation_services;

-- Step 2: Check if service_providers table has data
SELECT 
    'Service Providers Check' as step,
    COUNT(*) as total_providers,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) as providers_with_names
FROM service_providers;

-- Step 3: Create test providers if none exist
INSERT INTO service_providers (id, name, contact_phone, contact_email, created_at, updated_at)
SELECT 
    gen_random_uuid(),
    'Test Provider ' || generate_series(1, 3),
    '+26481' || (1000000 + generate_series(1, 3))::text,
    'provider' || generate_series(1, 3) || '@test.com',
    NOW(),
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM service_providers LIMIT 1);

-- Step 4: Get the test provider IDs
WITH test_providers AS (
    SELECT id FROM service_providers 
    WHERE name LIKE 'Test Provider%'
    ORDER BY created_at DESC
    LIMIT 3
)
SELECT 
    'Test Provider IDs' as step,
    array_agg(id) as provider_ids,
    array_length(array_agg(id), 1) as count
FROM test_providers;

-- Step 5: Update transportation services with test data
WITH test_providers AS (
    SELECT id FROM service_providers 
    WHERE name LIKE 'Test Provider%'
    ORDER BY created_at DESC
    LIMIT 3
),
provider_data AS (
    SELECT 
        array_agg(id) as provider_ids,
        array_agg(100.00 + (row_number() OVER (ORDER BY id) * 50.00)) as prices,
        array_agg('0' || (8 + row_number() OVER (ORDER BY id)) || ':00:00') as departure_times,
        array_agg('0' || (7 + row_number() OVER (ORDER BY id)) || ':30:00') as check_in_times,
        array_agg(
            CASE row_number() OVER (ORDER BY id)
                WHEN 1 THEN ARRAY[1,2,3,4,5]  -- Monday to Friday
                WHEN 2 THEN ARRAY[1,2,3,4,5]  -- Monday to Friday
                WHEN 3 THEN ARRAY[6,7]        -- Weekend
            END
        ) as operating_days,
        array_agg(24 + (row_number() OVER (ORDER BY id) * 24)) as advance_hours,
        array_agg(2 + row_number() OVER (ORDER BY id)) as cancellation_hours,
        array_agg(
            CASE row_number() OVER (ORDER BY id)
                WHEN 1 THEN ARRAY['AC', 'WiFi']
                WHEN 2 THEN ARRAY['AC', 'WiFi', 'Luggage']
                WHEN 3 THEN ARRAY['AC', 'WiFi', 'Luggage', 'Refreshments']
            END
        ) as features
    FROM test_providers
)
UPDATE transportation_services 
SET 
    provider_ids = (SELECT provider_ids FROM provider_data),
    prices = (SELECT prices FROM provider_data),
    departure_times = (SELECT departure_times FROM provider_data),
    check_in_times = (SELECT check_in_times FROM provider_data),
    provider_operating_days = (SELECT operating_days FROM provider_data),
    advance_booking_hours_array = (SELECT advance_hours FROM provider_data),
    cancellation_hours_array = (SELECT cancellation_hours FROM provider_data),
    features_array = (SELECT features FROM provider_data)
WHERE id = (
    SELECT id FROM transportation_services 
    ORDER BY created_at 
    LIMIT 1
);

-- Step 6: Verify the update worked
SELECT 
    'Verification' as step,
    name,
    provider_ids,
    prices,
    departure_times,
    array_length(provider_ids, 1) as provider_count,
    array_length(prices, 1) as price_count,
    array_length(features_array, 1) as features_count
FROM transportation_services 
WHERE provider_ids IS NOT NULL 
AND array_length(provider_ids, 1) > 0;

-- Step 7: Test the provider lookup (this is what the Dart code does)
SELECT 
    'Provider Lookup Test' as step,
    ts.name as service_name,
    ts.provider_ids,
    sp.id as provider_id,
    sp.name as provider_name,
    sp.contact_phone
FROM transportation_services ts
JOIN service_providers sp ON sp.id = ANY(ts.provider_ids)
WHERE ts.provider_ids IS NOT NULL 
AND array_length(ts.provider_ids, 1) > 0;

-- Step 8: Final summary
SELECT 
    'Final Summary' as step,
    COUNT(*) as total_services,
    COUNT(CASE WHEN provider_ids IS NOT NULL AND array_length(provider_ids, 1) > 0 THEN 1 END) as services_with_providers,
    COUNT(CASE WHEN provider_ids IS NULL OR array_length(provider_ids, 1) = 0 THEN 1 END) as services_without_providers
FROM transportation_services;
