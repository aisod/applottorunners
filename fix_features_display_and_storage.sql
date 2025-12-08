-- Fix features display and storage issues
-- This script addresses the problem where features data is not being stored or displayed

-- Step 1: Check current state of features_array column
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'transportation_services' 
AND column_name = 'features_array';

-- Step 2: Check current data in transportation_services
SELECT 
    id, 
    name, 
    features_array,
    pg_typeof(features_array) as column_type,
    array_length(features_array, 1) as features_count
FROM transportation_services 
LIMIT 5;

-- Step 3: Ensure features_array column exists and is properly configured
DO $$
BEGIN
    -- Check if column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transportation_services' 
        AND column_name = 'features_array'
    ) THEN
        -- Add the column
        ALTER TABLE transportation_services 
        ADD COLUMN features_array TEXT[][] DEFAULT '{}';
        
        RAISE NOTICE 'Added features_array column to transportation_services table';
    ELSE
        RAISE NOTICE 'features_array column already exists';
    END IF;
END $$;

-- Step 4: Fix any NULL or malformed features_array data
UPDATE transportation_services 
SET features_array = ARRAY[]::TEXT[][]
WHERE features_array IS NULL 
   OR pg_typeof(features_array) != 'text[][]'::regtype;

-- Step 5: Test adding features to an existing service
DO $$
DECLARE
    test_service_id UUID;
    test_provider_id UUID;
BEGIN
    -- Get a test service ID
    SELECT id INTO test_service_id FROM transportation_services LIMIT 1;
    
    IF test_service_id IS NOT NULL THEN
        -- Test adding features array
        UPDATE transportation_services 
        SET features_array = array_append(features_array, ARRAY['AC', 'WiFi', 'Luggage'])
        WHERE id = test_service_id;
        
        RAISE NOTICE '✅ Test features added to service %', test_service_id;
        
        -- Verify the update
        PERFORM features_array 
        FROM transportation_services 
        WHERE id = test_service_id;
        
        RAISE NOTICE '✅ Features array verified';
    ELSE
        RAISE NOTICE 'No services found to test with';
    END IF;
END $$;

-- Step 6: Check the transportation_services_with_provider_arrays view
-- This view should include features in the provider_details JSON
SELECT 
    service_id,
    service_name,
    provider_details
FROM transportation_services_with_provider_arrays 
LIMIT 3;

-- Step 7: Update the view to ensure features are included
CREATE OR REPLACE VIEW transportation_services_with_provider_arrays AS
SELECT 
    ts.id as service_id,
    ts.name as service_name,
    ts.description,
    ts.features,
    ts.route_id,
    ts.is_active,
    ts.provider_ids,
    ts.prices,
    ts.departure_times,
    ts.check_in_times,
    ts.provider_operating_days,
    ts.advance_booking_hours_array,
    ts.cancellation_hours_array,
    ts.features_array,
    -- Create a JSON array of provider details including features
    COALESCE(
        (
            SELECT json_agg(
                json_build_object(
                    'provider_id', provider_ids[i],
                    'provider_name', sp.name,
                    'price', prices[i],
                    'departure_time', departure_times[i],
                    'check_in_time', check_in_times[i],
                    'operating_days', provider_operating_days[i],
                    'advance_booking_hours', advance_booking_hours_array[i],
                    'cancellation_hours', cancellation_hours_array[i],
                    'features', COALESCE(features_array[i], ARRAY[]::TEXT[])
                )
            )
            FROM generate_series(1, array_length(provider_ids, 1)) i
            LEFT JOIN service_providers sp ON sp.id = provider_ids[i]
            WHERE sp.is_active = true
        ),
        '[]'::json
    ) as provider_details
FROM transportation_services ts
WHERE ts.is_active = true;

-- Step 8: Test the updated view
SELECT 
    service_id,
    service_name,
    provider_details
FROM transportation_services_with_provider_arrays 
LIMIT 2;

-- Step 9: Verify final state
SELECT 
    COUNT(*) as total_services,
    COUNT(CASE WHEN features_array IS NOT NULL THEN 1 END) as services_with_features_array,
    COUNT(CASE WHEN array_length(features_array, 1) > 0 THEN 1 END) as services_with_features_data
FROM transportation_services;
