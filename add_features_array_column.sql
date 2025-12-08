-- Add features array column to transportation_services table
-- This allows each provider to have their own features

-- 1. Add features_array column for per-provider features
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS features_array TEXT[][] DEFAULT '{}';

-- 2. Update the add_provider_to_service function to handle features
CREATE OR REPLACE FUNCTION add_provider_to_service(
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
        provider_ids,
        prices,
        departure_times,
        check_in_times,
        provider_operating_days,
        advance_booking_hours_array,
        cancellation_hours_array,
        features_array
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

-- 3. Update the update_service_provider function to handle features
CREATE OR REPLACE FUNCTION update_service_provider(
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
        provider_ids,
        prices,
        departure_times,
        check_in_times,
        provider_operating_days,
        advance_booking_hours_array,
        cancellation_hours_array,
        features_array
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

    -- Update arrays at the specific index
    UPDATE transportation_services SET
        prices = CASE WHEN new_price IS NOT NULL THEN 
            array_set(current_prices, provider_index, new_price) ELSE current_prices END,
        departure_times = CASE WHEN new_departure_time IS NOT NULL THEN 
            array_set(current_departure_times, provider_index, new_departure_time) ELSE current_departure_times END,
        check_in_times = CASE WHEN new_check_in_time IS NOT NULL THEN 
            array_set(current_check_in_times, provider_index, new_check_in_time) ELSE current_check_in_times END,
        provider_operating_days = CASE WHEN new_operating_days IS NOT NULL THEN 
            array_set(current_operating_days, provider_index, new_operating_days) ELSE current_operating_days END,
        advance_booking_hours_array = CASE WHEN new_advance_booking_hours IS NOT NULL THEN 
            array_set(current_advance_hours, provider_index, new_advance_booking_hours) ELSE current_advance_hours END,
        cancellation_hours_array = CASE WHEN new_cancellation_hours IS NOT NULL THEN 
            array_set(current_cancellation_hours, provider_index, new_cancellation_hours) ELSE current_cancellation_hours END,
        features_array = CASE WHEN new_features IS NOT NULL THEN 
            array_set(current_features_array, provider_index, new_features) ELSE current_features_array END,
        updated_at = NOW()
    WHERE id = service_uuid;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 4. Update the view to include features in provider details
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
    -- Create a JSON array of provider details
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
                    'features', features_array[i]
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

-- 5. Add comment for documentation
COMMENT ON COLUMN transportation_services.features_array IS 'Array of features arrays (TEXT[][]), each provider has TEXT[] of features like AC, WiFi, Luggage';

-- 6. Create helper function to set array element at specific index
CREATE OR REPLACE FUNCTION array_set(arr anyarray, index int, value anyelement)
RETURNS anyarray AS $$
BEGIN
    IF index < 1 OR index > array_length(arr, 1) THEN
        RAISE EXCEPTION 'Index % is out of bounds for array of length %', index, array_length(arr, 1);
    END IF;
    
    arr[index] := value;
    RETURN arr;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 7. Create function to normalize features array dimensions
CREATE OR REPLACE FUNCTION normalize_features_array(features TEXT[][])
RETURNS TEXT[][] AS $$
DECLARE
    result TEXT[][];
    max_length INTEGER := 0;
    normalized_features TEXT[];
BEGIN
    -- Find the maximum length of feature arrays
    FOR i IN 1..array_length(features, 1) LOOP
        IF array_length(features[i], 1) > max_length THEN
            max_length := array_length(features[i], 1);
        END IF;
    END LOOP;
    
    -- If no features exist, return empty array
    IF max_length IS NULL OR max_length = 0 THEN
        RETURN ARRAY[]::TEXT[][];
    END IF;
    
    -- Normalize all feature arrays to the same length
    FOR i IN 1..array_length(features, 1) LOOP
        normalized_features := features[i];
        
        -- Pad with empty strings to match max_length
        WHILE array_length(normalized_features, 1) < max_length LOOP
            normalized_features := array_append(normalized_features, '');
        END LOOP;
        
        result := array_append(result, normalized_features);
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 8. Update the add_provider_to_service function to handle features properly
CREATE OR REPLACE FUNCTION add_provider_to_service(
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
    normalized_features TEXT[];
BEGIN
    -- Get current arrays
    SELECT 
        provider_ids,
        prices,
        departure_times,
        check_in_times,
        provider_operating_days,
        advance_booking_hours_array,
        cancellation_hours_array,
        features_array
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

    -- Normalize features array dimensions
    current_features_array := normalize_features_array(current_features_array);
    
    -- Normalize new provider features to match existing dimensions
    normalized_features := provider_features;
    IF array_length(current_features_array, 1) > 0 THEN
        WHILE array_length(normalized_features, 1) < array_length(current_features_array[1], 1) LOOP
            normalized_features := array_append(normalized_features, '');
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
        features_array = array_append(current_features_array, normalized_features),
        updated_at = NOW()
    WHERE id = service_uuid;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 9. Update the update_service_provider function to handle features properly
CREATE OR REPLACE FUNCTION update_service_provider(
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
    normalized_features TEXT[];
BEGIN
    -- Get current arrays
    SELECT 
        provider_ids,
        prices,
        departure_times,
        check_in_times,
        provider_operating_days,
        advance_booking_hours_array,
        cancellation_hours_array,
        features_array
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

    -- Normalize features array dimensions
    current_features_array := normalize_features_array(current_features_array);

    -- Update arrays at the specific index
    UPDATE transportation_services SET
        prices = CASE WHEN new_price IS NOT NULL THEN 
            array_set(current_prices, provider_index, new_price) ELSE current_prices END,
        departure_times = CASE WHEN new_departure_time IS NOT NULL THEN 
            array_set(current_departure_times, provider_index, new_departure_time) ELSE current_departure_times END,
        check_in_times = CASE WHEN new_check_in_time IS NOT NULL THEN 
            array_set(current_check_in_times, provider_index, new_check_in_time) ELSE current_check_in_times END,
        provider_operating_days = CASE WHEN new_operating_days IS NOT NULL THEN 
            array_set(current_operating_days, provider_index, new_operating_days) ELSE current_operating_days END,
        advance_booking_hours_array = CASE WHEN new_advance_booking_hours IS NOT NULL THEN 
            array_set(current_advance_hours, provider_index, new_advance_booking_hours) ELSE current_advance_hours END,
        cancellation_hours_array = CASE WHEN new_cancellation_hours IS NOT NULL THEN 
            array_set(current_cancellation_hours, provider_index, new_cancellation_hours) ELSE current_cancellation_hours END,
        features_array = CASE WHEN new_features IS NOT NULL THEN 
            array_set(current_features_array, provider_index, new_features) ELSE current_features_array END,
        updated_at = NOW()
    WHERE id = service_uuid;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
