-- Comprehensive diagnosis and fix for transportation service providers
-- This script will identify why services show 0 providers and fix the issue

-- Step 1: Check current state of transportation_services table
SELECT 
    '=== TRANSPORTATION SERVICES DIAGNOSIS ===' as section;

SELECT 
    'Current Services' as step,
    COUNT(*) as total_services,
    COUNT(CASE WHEN provider_ids IS NOT NULL AND array_length(provider_ids, 1) > 0 THEN 1 END) as services_with_providers,
    COUNT(CASE WHEN provider_ids IS NULL OR array_length(provider_ids, 1) = 0 OR array_length(provider_ids, 1) IS NULL THEN 1 END) as services_without_providers
FROM transportation_services;

-- Step 2: Show detailed service information
SELECT 
    'Service Details' as step,
    id,
    name,
    provider_ids,
    array_length(provider_ids, 1) as provider_count,
    prices,
    departure_times,
    features_array,
    is_active
FROM transportation_services 
ORDER BY name;

-- Step 3: Check service_providers table
SELECT 
    '=== SERVICE PROVIDERS DIAGNOSIS ===' as section;

SELECT 
    'Current Providers' as step,
    COUNT(*) as total_providers,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) as providers_with_names
FROM service_providers;

-- Step 4: Show existing providers
SELECT 
    'Provider Details' as step,
    id,
    name,
    contact_phone,
    contact_email,
    created_at
FROM service_providers 
ORDER BY created_at DESC;

-- Step 5: Create test providers if none exist
INSERT INTO service_providers (id, name, contact_phone, contact_email, created_at, updated_at)
SELECT 
    gen_random_uuid(),
    'Test Provider ' || generate_series(1, 5),
    '+26481' || (1000000 + generate_series(1, 5))::text,
    'provider' || generate_series(1, 5) || '@test.com',
    NOW(),
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM service_providers LIMIT 1);

-- Step 6: Get the newly created provider IDs
WITH new_providers AS (
    SELECT id FROM service_providers 
    WHERE name LIKE 'Test Provider%'
    ORDER BY created_at DESC
    LIMIT 5
)
SELECT 
    'New Provider IDs' as step,
    array_agg(id) as provider_ids,
    array_length(array_agg(id), 1) as count
FROM new_providers;

-- Step 7: Update transportation services with provider data
WITH provider_data AS (
    SELECT 
        array_agg(id ORDER BY created_at DESC) as provider_ids,
        array_agg(100.00 + (row_number() OVER (ORDER BY created_at DESC) * 50.00)) as prices,
        array_agg('0' || (8 + row_number() OVER (ORDER BY created_at DESC)) || ':00:00') as departure_times,
        array_agg('0' || (7 + row_number() OVER (ORDER BY created_at DESC)) || ':30:00') as check_in_times,
        array_agg(
            CASE row_number() OVER (ORDER BY created_at DESC)
                WHEN 1 THEN ARRAY[1,2,3,4,5]  -- Monday to Friday
                WHEN 2 THEN ARRAY[1,2,3,4,5]  -- Monday to Friday
                WHEN 3 THEN ARRAY[6,7]        -- Weekend
                WHEN 4 THEN ARRAY[1,2,3,4,5,6,7]  -- Every day
                WHEN 5 THEN ARRAY[1,2,3,4,5]  -- Monday to Friday
            END
        ) as operating_days,
        array_agg(24 + (row_number() OVER (ORDER BY created_at DESC) * 12)) as advance_hours,
        array_agg(2 + row_number() OVER (ORDER BY created_at DESC)) as cancellation_hours,
        array_agg(
            CASE row_number() OVER (ORDER BY created_at DESC)
                WHEN 1 THEN ARRAY['AC', 'WiFi']
                WHEN 2 THEN ARRAY['AC', 'WiFi', 'Luggage']
                WHEN 3 THEN ARRAY['AC', 'WiFi', 'Luggage', 'Refreshments']
                WHEN 4 THEN ARRAY['AC', 'WiFi', 'Luggage', 'Refreshments', 'Charging Ports']
                WHEN 5 THEN ARRAY['AC', 'WiFi', 'Luggage']
            END
        ) as features
    FROM service_providers 
    WHERE name LIKE 'Test Provider%'
    ORDER BY created_at DESC
    LIMIT 5
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
WHERE provider_ids IS NULL OR array_length(provider_ids, 1) = 0 OR array_length(provider_ids, 1) IS NULL;

-- Step 8: Verify the updates
SELECT 
    '=== VERIFICATION AFTER UPDATE ===' as section;

SELECT 
    'Updated Services' as step,
    COUNT(*) as total_services,
    COUNT(CASE WHEN provider_ids IS NOT NULL AND array_length(provider_ids, 1) > 0 THEN 1 END) as services_with_providers,
    COUNT(CASE WHEN provider_ids IS NULL OR array_length(provider_ids, 1) = 0 OR array_length(provider_ids, 1) IS NULL THEN 1 END) as services_without_providers
FROM transportation_services;

-- Step 9: Show updated service details
SELECT 
    'Updated Service Details' as step,
    id,
    name,
    provider_ids,
    array_length(provider_ids, 1) as provider_count,
    prices,
    departure_times,
    features_array,
    is_active
FROM transportation_services 
ORDER BY name;

-- Step 10: Test the provider lookup (simulating what the Dart code does)
SELECT 
    '=== PROVIDER LOOKUP TEST ===' as section;

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
AND array_length(ts.provider_ids, 1) > 0
ORDER BY ts.name, sp.name;

-- Step 11: Final summary
SELECT 
    '=== FINAL SUMMARY ===' as section;

SELECT 
    'Final State' as step,
    COUNT(*) as total_services,
    COUNT(CASE WHEN provider_ids IS NOT NULL AND array_length(provider_ids, 1) > 0 THEN 1 END) as services_with_providers,
    COUNT(CASE WHEN provider_ids IS NULL OR array_length(provider_ids, 1) = 0 OR array_length(provider_ids, 1) IS NULL THEN 1 END) as services_without_providers
FROM transportation_services;

SELECT 
    'Total Providers Available' as step,
    COUNT(*) as total_providers
FROM service_providers;
