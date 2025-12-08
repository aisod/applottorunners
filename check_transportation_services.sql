-- Check the current state of transportation services and their provider_ids
SELECT 
    id,
    name,
    provider_ids,
    array_length(provider_ids, 1) as provider_count,
    created_at
FROM transportation_services 
ORDER BY created_at DESC;

-- Check if there are any services with null provider_ids
SELECT 
    id,
    name,
    provider_ids,
    CASE 
        WHEN provider_ids IS NULL THEN 'NULL'
        WHEN array_length(provider_ids, 1) IS NULL THEN 'EMPTY'
        ELSE 'HAS_PROVIDERS'
    END as provider_status
FROM transportation_services 
WHERE provider_ids IS NULL OR array_length(provider_ids, 1) IS NULL;

-- Check service_providers table
SELECT 
    id,
    name,
    contact_phone,
    is_active
FROM service_providers 
ORDER BY name;
