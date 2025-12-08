-- Step-by-step fix for features array issues
-- This script handles the case where features_array column might not exist yet

-- Step 1: Check if features_array column exists, if not create it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transportation_services' 
        AND column_name = 'features_array'
    ) THEN
        ALTER TABLE transportation_services 
        ADD COLUMN features_array TEXT[][] DEFAULT '{}';
        
        RAISE NOTICE 'Added features_array column to transportation_services table';
    ELSE
        RAISE NOTICE 'features_array column already exists';
    END IF;
END $$;

-- Step 2: Create a simple normalization function that handles edge cases
CREATE OR REPLACE FUNCTION safe_normalize_features_array(features TEXT[][])
RETURNS TEXT[][] AS $$
DECLARE
    result TEXT[][];
    max_length INTEGER := 0;
    normalized_features TEXT[];
BEGIN
    -- Handle null or empty arrays
    IF features IS NULL OR array_length(features, 1) IS NULL OR array_length(features, 1) = 0 THEN
        RETURN ARRAY[]::TEXT[][];
    END IF;
    
    -- Find the maximum length of feature arrays
    FOR i IN 1..array_length(features, 1) LOOP
        IF features[i] IS NOT NULL AND array_length(features[i], 1) IS NOT NULL THEN
            IF array_length(features[i], 1) > max_length THEN
                max_length := array_length(features[i], 1);
            END IF;
        END IF;
    END LOOP;
    
    -- If no valid features found, return empty array
    IF max_length = 0 THEN
        RETURN ARRAY[]::TEXT[][];
    END IF;
    
    -- Normalize all feature arrays to the same length
    FOR i IN 1..array_length(features, 1) LOOP
        IF features[i] IS NOT NULL THEN
            normalized_features := features[i];
        ELSE
            normalized_features := ARRAY[]::TEXT[];
        END IF;
        
        -- Pad with empty strings to match max_length
        WHILE array_length(normalized_features, 1) < max_length LOOP
            normalized_features := array_append(normalized_features, '');
        END LOOP;
        
        result := array_append(result, normalized_features);
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 3: Fix existing data safely
DO $$
DECLARE
    service_record RECORD;
    fixed_features TEXT[][];
BEGIN
    -- Only process services that have features_array data
    FOR service_record IN 
        SELECT id, features_array 
        FROM transportation_services 
        WHERE features_array IS NOT NULL 
        AND features_array != '{}'
    LOOP
        BEGIN
            -- Try to normalize the features array
            fixed_features := safe_normalize_features_array(service_record.features_array);
            
            -- Update the service with normalized features
            UPDATE transportation_services 
            SET features_array = fixed_features,
                updated_at = NOW()
            WHERE id = service_record.id;
            
            RAISE NOTICE 'Fixed features array for service %', service_record.id;
            
        EXCEPTION WHEN OTHERS THEN
            -- If normalization fails, set to empty array
            UPDATE transportation_services 
            SET features_array = ARRAY[]::TEXT[][],
                updated_at = NOW()
            WHERE id = service_record.id;
            
            RAISE NOTICE 'Reset features array for service % due to error: %', service_record.id, SQLERRM;
        END;
    END LOOP;
END $$;

-- Step 4: Create a simple array_set function
CREATE OR REPLACE FUNCTION simple_array_set(arr anyarray, index int, value anyelement)
RETURNS anyarray AS $$
BEGIN
    IF arr IS NULL OR array_length(arr, 1) IS NULL THEN
        RAISE EXCEPTION 'Array is null or empty';
    END IF;
    
    IF index < 1 OR index > array_length(arr, 1) THEN
        RAISE EXCEPTION 'Index % is out of bounds for array of length %', index, array_length(arr, 1);
    END IF;
    
    arr[index] := value;
    RETURN arr;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 5: Create simplified add_provider_to_service function
CREATE OR REPLACE FUNCTION add_provider_to_service_simple(
    service_uuid UUID,
    provider_uuid UUID,
    provider_price DECIMAL(10,2),
    departure_time TIME,
    check_in_time TIME DEFAULT NULL,
    operating_days INTEGER[] DEFAULT '{1,2,3,4,5,6,7}',
    advance_booking_hours INTEGER DEFAULT 1,
    cancellation_hours INTEGER DEFAULT 2,
    provider_features TEXT[] DEFAULT '{}'
)
RETURNS BOOLEAN AS $$
DECLARE
    current_provider_ids UUID[];
    current_prices DECIMAL(10,2)[];
    current_departure_times TIME[];
    current_check_in_times TIME[];
    current_operating_days INTEGER[][];
    current_advance_hours INTEGER[];
    current_cancellation_hours INTEGER[];
    current_features_array TEXT[][];
BEGIN
    -- Get current arrays
    SELECT 
        COALESCE(provider_ids, ARRAY[]::UUID[]),
        COALESCE(prices, ARRAY[]::DECIMAL(10,2)[]),
        COALESCE(departure_times, ARRAY[]::TIME[]),
        COALESCE(check_in_times, ARRAY[]::TIME[]),
        COALESCE(provider_operating_days, ARRAY[]::INTEGER[][]),
        COALESCE(advance_booking_hours_array, ARRAY[]::INTEGER[]),
        COALESCE(cancellation_hours_array, ARRAY[]::INTEGER[]),
        COALESCE(features_array, ARRAY[]::TEXT[][])
    INTO 
        current_provider_ids,
        current_prices,
        current_departure_times,
        current_check_in_times,
        current_operating_days,
        current_advance_hours,
        current_cancellation_hours,
        current_features_array
    FROM transportation_services 
    WHERE id = service_uuid;

    -- Check if provider already exists
    IF provider_uuid = ANY(current_provider_ids) THEN
        RAISE EXCEPTION 'Provider already exists in this service';
    END IF;

    -- Normalize features array
    current_features_array := safe_normalize_features_array(current_features_array);
    
    -- Normalize new provider features to match existing dimensions
    IF array_length(current_features_array, 1) > 0 AND array_length(current_features_array[1], 1) > 0 THEN
        WHILE array_length(provider_features, 1) < array_length(current_features_array[1], 1) LOOP
            provider_features := array_append(provider_features, '');
        END LOOP;
    END IF;

    -- Append new provider data to arrays
    UPDATE transportation_services SET
        provider_ids = array_append(current_provider_ids, provider_uuid),
        prices = array_append(current_prices, provider_price),
        departure_times = array_append(current_departure_times, departure_time),
        check_in_times = array_append(current_check_in_times, check_in_time),
        provider_operating_days = array_append(current_operating_days, operating_days),
        advance_booking_hours_array = array_append(current_advance_hours, advance_booking_hours),
        cancellation_hours_array = array_append(current_cancellation_hours, cancellation_hours),
        features_array = array_append(current_features_array, provider_features),
        updated_at = NOW()
    WHERE id = service_uuid;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create simplified update_service_provider function
CREATE OR REPLACE FUNCTION update_service_provider_simple(
    service_uuid UUID,
    provider_uuid UUID,
    new_price DECIMAL(10,2) DEFAULT NULL,
    new_departure_time TIME DEFAULT NULL,
    new_check_in_time TIME DEFAULT NULL,
    new_operating_days INTEGER[] DEFAULT NULL,
    new_advance_booking_hours INTEGER DEFAULT NULL,
    new_cancellation_hours INTEGER DEFAULT NULL,
    new_features TEXT[] DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    provider_index INTEGER;
    current_provider_ids UUID[];
    current_prices DECIMAL(10,2)[];
    current_departure_times TIME[];
    current_check_in_times TIME[];
    current_operating_days INTEGER[][];
    current_advance_hours INTEGER[];
    current_cancellation_hours INTEGER[];
    current_features_array TEXT[][];
BEGIN
    -- Get current arrays
    SELECT 
        COALESCE(provider_ids, ARRAY[]::UUID[]),
        COALESCE(prices, ARRAY[]::DECIMAL(10,2)[]),
        COALESCE(departure_times, ARRAY[]::TIME[]),
        COALESCE(check_in_times, ARRAY[]::TIME[]),
        COALESCE(provider_operating_days, ARRAY[]::INTEGER[][]),
        COALESCE(advance_booking_hours_array, ARRAY[]::INTEGER[]),
        COALESCE(cancellation_hours_array, ARRAY[]::INTEGER[]),
        COALESCE(features_array, ARRAY[]::TEXT[][])
    INTO 
        current_provider_ids,
        current_prices,
        current_departure_times,
        current_check_in_times,
        current_operating_days,
        current_advance_hours,
        current_cancellation_hours,
        current_features_array
    FROM transportation_services 
    WHERE id = service_uuid;

    -- Find provider index
    SELECT array_position(current_provider_ids, provider_uuid) INTO provider_index;
    
    IF provider_index IS NULL THEN
        RAISE EXCEPTION 'Provider not found in this service';
    END IF;

    -- Normalize features array
    current_features_array := safe_normalize_features_array(current_features_array);

    -- Update arrays at the specific index
    UPDATE transportation_services SET
        prices = CASE WHEN new_price IS NOT NULL THEN 
            simple_array_set(current_prices, provider_index, new_price) ELSE current_prices END,
        departure_times = CASE WHEN new_departure_time IS NOT NULL THEN 
            simple_array_set(current_departure_times, provider_index, new_departure_time) ELSE current_departure_times END,
        check_in_times = CASE WHEN new_check_in_time IS NOT NULL THEN 
            simple_array_set(current_check_in_times, provider_index, new_check_in_time) ELSE current_check_in_times END,
        provider_operating_days = CASE WHEN new_operating_days IS NOT NULL THEN 
            simple_array_set(current_operating_days, provider_index, new_operating_days) ELSE current_operating_days END,
        advance_booking_hours_array = CASE WHEN new_advance_booking_hours IS NOT NULL THEN 
            simple_array_set(current_advance_hours, provider_index, new_advance_booking_hours) ELSE current_advance_hours END,
        cancellation_hours_array = CASE WHEN new_cancellation_hours IS NOT NULL THEN 
            simple_array_set(current_cancellation_hours, provider_index, new_cancellation_hours) ELSE current_cancellation_hours END,
        features_array = CASE WHEN new_features IS NOT NULL THEN 
            simple_array_set(current_features_array, provider_index, new_features) ELSE current_features_array END,
        updated_at = NOW()
    WHERE id = service_uuid;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Add helpful comments
COMMENT ON FUNCTION safe_normalize_features_array IS 'Safely normalizes features arrays with proper null handling';
COMMENT ON FUNCTION add_provider_to_service_simple IS 'Simplified function to add provider with features support';
COMMENT ON FUNCTION update_service_provider_simple IS 'Simplified function to update provider with features support';
