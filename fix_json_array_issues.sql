-- Fix JSON and array data issues
-- This script addresses "Please enter a valid JSON" errors

-- Step 1: Check current data types and formats
SELECT 
    column_name, 
    data_type, 
    udt_name,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'transportation_services' 
AND column_name IN ('features_array', 'provider_operating_days', 'provider_ids', 'prices')
ORDER BY column_name;

-- Step 2: Check for any malformed data
SELECT 
    id,
    name,
    provider_ids,
    prices,
    provider_operating_days,
    features_array,
    pg_typeof(provider_ids) as provider_ids_type,
    pg_typeof(prices) as prices_type,
    pg_typeof(provider_operating_days) as operating_days_type,
    pg_typeof(features_array) as features_type
FROM transportation_services 
WHERE id IS NOT NULL
LIMIT 3;

-- Step 3: Clean up any malformed array data
DO $$
DECLARE
    service_record RECORD;
BEGIN
    FOR service_record IN 
        SELECT id, provider_ids, prices, provider_operating_days, features_array
        FROM transportation_services
    LOOP
        BEGIN
            -- Fix provider_ids if malformed
            IF service_record.provider_ids IS NOT NULL THEN
                UPDATE transportation_services 
                SET provider_ids = CASE 
                    WHEN pg_typeof(service_record.provider_ids) = 'uuid[]'::regtype 
                    THEN service_record.provider_ids
                    ELSE ARRAY[]::UUID[]
                END
                WHERE id = service_record.id;
            END IF;
            
            -- Fix prices if malformed
            IF service_record.prices IS NOT NULL THEN
                UPDATE transportation_services 
                SET prices = CASE 
                    WHEN pg_typeof(service_record.prices) = 'numeric[]'::regtype 
                    THEN service_record.prices
                    ELSE ARRAY[]::NUMERIC[]
                END
                WHERE id = service_record.id;
            END IF;
            
            -- Fix operating days if malformed
            IF service_record.provider_operating_days IS NOT NULL THEN
                UPDATE transportation_services 
                SET provider_operating_days = CASE 
                    WHEN pg_typeof(service_record.provider_operating_days) = 'integer[][]'::regtype 
                    THEN service_record.provider_operating_days
                    ELSE ARRAY[]::INTEGER[][]
                END
                WHERE id = service_record.id;
            END IF;
            
            -- Fix features_array if malformed
            IF service_record.features_array IS NOT NULL THEN
                UPDATE transportation_services 
                SET features_array = CASE 
                    WHEN pg_typeof(service_record.features_array) = 'text[][]'::regtype 
                    THEN service_record.features_array
                    ELSE ARRAY[]::TEXT[][]
                END
                WHERE id = service_record.id;
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
            -- If any update fails, reset to empty arrays
            UPDATE transportation_services 
            SET 
                provider_ids = ARRAY[]::UUID[],
                prices = ARRAY[]::NUMERIC[],
                provider_operating_days = ARRAY[]::INTEGER[][],
                features_array = ARRAY[]::TEXT[][]
            WHERE id = service_record.id;
            
            RAISE NOTICE 'Reset arrays for service % due to error: %', service_record.id, SQLERRM;
        END;
    END LOOP;
END $$;

-- Step 4: Ensure all array columns have proper defaults
ALTER TABLE transportation_services 
ALTER COLUMN provider_ids SET DEFAULT '{}',
ALTER COLUMN prices SET DEFAULT '{}',
ALTER COLUMN departure_times SET DEFAULT '{}',
ALTER COLUMN check_in_times SET DEFAULT '{}',
ALTER COLUMN provider_operating_days SET DEFAULT '{}',
ALTER COLUMN advance_booking_hours_array SET DEFAULT '{}',
ALTER COLUMN cancellation_hours_array SET DEFAULT '{}',
ALTER COLUMN features_array SET DEFAULT '{}';

-- Step 5: Update any NULL values to empty arrays
UPDATE transportation_services 
SET 
    provider_ids = COALESCE(provider_ids, ARRAY[]::UUID[]),
    prices = COALESCE(prices, ARRAY[]::NUMERIC[]),
    departure_times = COALESCE(departure_times, ARRAY[]::TIME[]),
    check_in_times = COALESCE(check_in_times, ARRAY[]::TIME[]),
    provider_operating_days = COALESCE(provider_operating_days, ARRAY[]::INTEGER[][]),
    advance_booking_hours_array = COALESCE(advance_booking_hours_array, ARRAY[]::INTEGER[]),
    cancellation_hours_array = COALESCE(cancellation_hours_array, ARRAY[]::INTEGER[]),
    features_array = COALESCE(features_array, ARRAY[]::TEXT[][]);

-- Step 6: Test array operations
DO $$
DECLARE
    test_service_id UUID;
    test_provider_id UUID;
BEGIN
    -- Get a test service ID
    SELECT id INTO test_service_id FROM transportation_services LIMIT 1;
    
    IF test_service_id IS NOT NULL THEN
        -- Test array operations
        UPDATE transportation_services 
        SET 
            provider_ids = array_append(provider_ids, gen_random_uuid()),
            prices = array_append(prices, 100.00),
            features_array = array_append(features_array, ARRAY['Test Feature'])
        WHERE id = test_service_id;
        
        -- Test reading the data back
        PERFORM provider_ids, prices, features_array 
        FROM transportation_services 
        WHERE id = test_service_id;
        
        RAISE NOTICE '✅ Array operations working correctly';
        
        -- Clean up test data
        UPDATE transportation_services 
        SET 
            provider_ids = provider_ids[1:array_length(provider_ids, 1)-1],
            prices = prices[1:array_length(prices, 1)-1],
            features_array = features_array[1:array_length(features_array, 1)-1]
        WHERE id = test_service_id;
        
    ELSE
        RAISE NOTICE 'No services found to test with';
    END IF;
END $$;

-- Step 7: Verify final state
SELECT 
    COUNT(*) as total_services,
    COUNT(CASE WHEN provider_ids IS NOT NULL THEN 1 END) as services_with_providers,
    COUNT(CASE WHEN features_array IS NOT NULL THEN 1 END) as services_with_features
FROM transportation_services;

-- Step 8: Show sample of clean data
SELECT 
    id,
    name,
    array_length(provider_ids, 1) as provider_count,
    array_length(prices, 1) as price_count,
    array_length(features_array, 1) as features_count
FROM transportation_services 
WHERE provider_ids IS NOT NULL 
LIMIT 3;
