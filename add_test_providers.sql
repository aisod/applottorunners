-- Add test providers and link them to services
-- This will help test if the provider retrieval is working

-- Step 1: Check if there are any existing providers
SELECT COUNT(*) as existing_providers FROM service_providers;

-- Step 2: Add test providers if none exist
INSERT INTO service_providers (id, name, contact_phone, contact_email, created_at, updated_at)
VALUES 
    (gen_random_uuid(), 'Test Provider 1', '+264811234567', 'provider1@test.com', NOW(), NOW()),
    (gen_random_uuid(), 'Test Provider 2', '+264812345678', 'provider2@test.com', NOW(), NOW()),
    (gen_random_uuid(), 'Test Provider 3', '+264813456789', 'provider3@test.com', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 3: Get the provider IDs we just created
WITH new_providers AS (
    SELECT id FROM service_providers 
    WHERE name LIKE 'Test Provider%'
    ORDER BY created_at DESC
    LIMIT 3
)
SELECT array_agg(id) as provider_ids FROM new_providers;

-- Step 4: Update the first transportation service with test providers
WITH new_providers AS (
    SELECT id FROM service_providers 
    WHERE name LIKE 'Test Provider%'
    ORDER BY created_at DESC
    LIMIT 3
),
provider_array AS (
    SELECT array_agg(id) as provider_ids FROM new_providers
)
UPDATE transportation_services 
SET 
    provider_ids = (SELECT provider_ids FROM provider_array),
    prices = ARRAY[100.00, 150.00, 200.00],
    departure_times = ARRAY['08:00:00', '10:00:00', '12:00:00'],
    check_in_times = ARRAY['07:30:00', '09:30:00', '11:30:00'],
    provider_operating_days = ARRAY[
        ARRAY[1,2,3,4,5],  -- Monday to Friday
        ARRAY[1,2,3,4,5],  -- Monday to Friday  
        ARRAY[6,7]         -- Weekend
    ],
    advance_booking_hours_array = ARRAY[24, 48, 72],
    cancellation_hours_array = ARRAY[2, 4, 6],
    features_array = ARRAY[
        ARRAY['AC', 'WiFi'],
        ARRAY['AC', 'WiFi', 'Luggage'],
        ARRAY['AC', 'WiFi', 'Luggage', 'Refreshments']
    ]
WHERE id = (
    SELECT id FROM transportation_services 
    ORDER BY created_at 
    LIMIT 1
);

-- Step 5: Verify the update
SELECT 
    name,
    provider_ids,
    prices,
    departure_times,
    array_length(provider_ids, 1) as provider_count,
    array_length(prices, 1) as price_count
FROM transportation_services 
WHERE provider_ids IS NOT NULL 
AND array_length(provider_ids, 1) > 0
LIMIT 3;

-- Step 6: Test the provider lookup
SELECT 
    ts.name as service_name,
    ts.provider_ids,
    sp.name as provider_name,
    sp.contact_phone
FROM transportation_services ts
JOIN service_providers sp ON sp.id = ANY(ts.provider_ids)
WHERE ts.provider_ids IS NOT NULL 
AND array_length(ts.provider_ids, 1) > 0
LIMIT 5;
