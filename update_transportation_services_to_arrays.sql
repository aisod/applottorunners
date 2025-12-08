-- Migration script to update transportation_services table to support multiple providers using arrays
-- This modifies existing columns to be arrays instead of single values

-- 1. Add provider_ids array to track multiple providers
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS provider_ids UUID[] DEFAULT '{}';

-- 2. Modify existing columns to be arrays for multiple provider data

-- Price array (each index corresponds to a provider)
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS prices DECIMAL(10,2)[] DEFAULT '{}';

-- Departure times array (each index corresponds to a provider)
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS departure_times TIME[] DEFAULT '{}';

-- Check-in times array (each index corresponds to a provider)
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS check_in_times TIME[] DEFAULT '{}';

-- Operating days array for each provider (array of text arrays)
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS provider_operating_days TEXT[][] DEFAULT '{}';

-- Advance booking hours array (each index corresponds to a provider)
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS advance_booking_hours_array INTEGER[] DEFAULT '{}';

-- Cancellation hours array (each index corresponds to a provider)
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS cancellation_hours_array INTEGER[] DEFAULT '{}';

-- 3. Create a function to migrate existing single-provider data to arrays
CREATE OR REPLACE FUNCTION migrate_single_provider_to_arrays()
RETURNS void AS $$
DECLARE
    service_record RECORD;
BEGIN
    -- Loop through existing transportation services that have single provider data
    FOR service_record IN 
        SELECT id, provider_id, price, departure_time, check_in_time, 
               days_of_week, advance_booking_hours, cancellation_hours
        FROM transportation_services 
        WHERE provider_id IS NOT NULL
    LOOP
        -- Update to array format
        UPDATE transportation_services 
        SET 
            provider_ids = ARRAY[service_record.provider_id],
            prices = ARRAY[COALESCE(service_record.price, 0)],
            departure_times = CASE 
                WHEN service_record.departure_time IS NOT NULL 
                THEN ARRAY[service_record.departure_time] 
                ELSE '{}' 
            END,
            check_in_times = CASE 
                WHEN service_record.check_in_time IS NOT NULL 
                THEN ARRAY[service_record.check_in_time] 
                ELSE '{}' 
            END,
            provider_operating_days = CASE 
                WHEN service_record.days_of_week IS NOT NULL AND array_length(service_record.days_of_week, 1) > 0
                THEN ARRAY[service_record.days_of_week] 
                ELSE '{}' 
            END,
            advance_booking_hours_array = ARRAY[COALESCE(service_record.advance_booking_hours, 1)],
            cancellation_hours_array = ARRAY[COALESCE(service_record.cancellation_hours, 2)]
        WHERE id = service_record.id;
    END LOOP;
    
    RAISE NOTICE 'Migration to arrays completed successfully';
END;
$$ LANGUAGE plpgsql;

-- 4. Execute the migration (uncomment to run)
-- SELECT migrate_single_provider_to_arrays();

-- 5. Create indexes for better performance on array columns
CREATE INDEX IF NOT EXISTS idx_transportation_services_provider_ids ON transportation_services USING GIN(provider_ids);

-- 6. Create a function to add a provider to a service
CREATE OR REPLACE FUNCTION add_provider_to_service(
    p_service_id UUID,
    p_provider_id UUID,
    p_price DECIMAL(10,2),
    p_departure_time TIME,
    p_check_in_time TIME DEFAULT NULL,
    p_operating_days TEXT[] DEFAULT '{}',
    p_advance_booking_hours INTEGER DEFAULT 1,
    p_cancellation_hours INTEGER DEFAULT 2
)
RETURNS boolean AS $$
BEGIN
    -- Check if provider already exists for this service
    IF p_provider_id = ANY(
        SELECT provider_ids FROM transportation_services WHERE id = p_service_id
    ) THEN
        RAISE EXCEPTION 'Provider already exists for this service';
    END IF;

    -- Add provider data to arrays
    UPDATE transportation_services 
    SET 
        provider_ids = array_append(provider_ids, p_provider_id),
        prices = array_append(prices, p_price),
        departure_times = array_append(departure_times, p_departure_time),
        check_in_times = array_append(check_in_times, p_check_in_time),
        provider_operating_days = array_append(provider_operating_days, p_operating_days),
        advance_booking_hours_array = array_append(advance_booking_hours_array, p_advance_booking_hours),
        cancellation_hours_array = array_append(cancellation_hours_array, p_cancellation_hours),
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- 7. Create a function to remove a provider from a service
CREATE OR REPLACE FUNCTION remove_provider_from_service(
    p_service_id UUID,
    p_provider_id UUID
)
RETURNS boolean AS $$
DECLARE
    provider_index INTEGER;
BEGIN
    -- Find the index of the provider
    SELECT array_position(provider_ids, p_provider_id) INTO provider_index
    FROM transportation_services 
    WHERE id = p_service_id;

    IF provider_index IS NULL THEN
        RAISE EXCEPTION 'Provider not found for this service';
    END IF;

    -- Remove provider data from all arrays at the same index
    UPDATE transportation_services 
    SET 
        provider_ids = array_remove(provider_ids, p_provider_id),
        prices = (
            SELECT array_agg(val ORDER BY ordinality)
            FROM unnest(prices) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        departure_times = (
            SELECT array_agg(val ORDER BY ordinality)
            FROM unnest(departure_times) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        check_in_times = (
            SELECT array_agg(val ORDER BY ordinality)
            FROM unnest(check_in_times) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        provider_operating_days = (
            SELECT array_agg(val ORDER BY ordinality)
            FROM unnest(provider_operating_days) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        advance_booking_hours_array = (
            SELECT array_agg(val ORDER BY ordinality)
            FROM unnest(advance_booking_hours_array) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        cancellation_hours_array = (
            SELECT array_agg(val ORDER BY ordinality)
            FROM unnest(cancellation_hours_array) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- 8. Create a function to update provider data in a service
CREATE OR REPLACE FUNCTION update_service_provider(
    p_service_id UUID,
    p_provider_id UUID,
    p_price DECIMAL(10,2) DEFAULT NULL,
    p_departure_time TIME DEFAULT NULL,
    p_check_in_time TIME DEFAULT NULL,
    p_operating_days TEXT[] DEFAULT NULL,
    p_advance_booking_hours INTEGER DEFAULT NULL,
    p_cancellation_hours INTEGER DEFAULT NULL
)
RETURNS boolean AS $$
DECLARE
    provider_index INTEGER;
    current_prices DECIMAL(10,2)[];
    current_departure_times TIME[];
    current_check_in_times TIME[];
    current_operating_days TEXT[][];
    current_advance_hours INTEGER[];
    current_cancellation_hours INTEGER[];
BEGIN
    -- Find the index of the provider
    SELECT array_position(provider_ids, p_provider_id) INTO provider_index
    FROM transportation_services 
    WHERE id = p_service_id;

    IF provider_index IS NULL THEN
        RAISE EXCEPTION 'Provider not found for this service';
    END IF;

    -- Get current arrays
    SELECT prices, departure_times, check_in_times, provider_operating_days,
           advance_booking_hours_array, cancellation_hours_array
    INTO current_prices, current_departure_times, current_check_in_times,
         current_operating_days, current_advance_hours, current_cancellation_hours
    FROM transportation_services 
    WHERE id = p_service_id;

    -- Update arrays at the specific index
    IF p_price IS NOT NULL THEN
        current_prices[provider_index] = p_price;
    END IF;
    
    IF p_departure_time IS NOT NULL THEN
        current_departure_times[provider_index] = p_departure_time;
    END IF;
    
    IF p_check_in_time IS NOT NULL THEN
        current_check_in_times[provider_index] = p_check_in_time;
    END IF;
    
    IF p_operating_days IS NOT NULL THEN
        current_operating_days[provider_index] = p_operating_days;
    END IF;
    
    IF p_advance_booking_hours IS NOT NULL THEN
        current_advance_hours[provider_index] = p_advance_booking_hours;
    END IF;
    
    IF p_cancellation_hours IS NOT NULL THEN
        current_cancellation_hours[provider_index] = p_cancellation_hours;
    END IF;

    -- Update the record
    UPDATE transportation_services 
    SET 
        prices = current_prices,
        departure_times = current_departure_times,
        check_in_times = current_check_in_times,
        provider_operating_days = current_operating_days,
        advance_booking_hours_array = current_advance_hours,
        cancellation_hours_array = current_cancellation_hours,
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- 9. Create a view for easy querying of services with provider details
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
                    'cancellation_hours', cancellation_hours_array[i]
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

-- 10. Add comments for documentation
COMMENT ON COLUMN transportation_services.provider_ids IS 'Array of provider UUIDs associated with this service';
COMMENT ON COLUMN transportation_services.prices IS 'Array of prices, each corresponding to a provider (same index as provider_ids)';
COMMENT ON COLUMN transportation_services.departure_times IS 'Array of departure times, each corresponding to a provider';
COMMENT ON COLUMN transportation_services.check_in_times IS 'Array of check-in times, each corresponding to a provider';
COMMENT ON COLUMN transportation_services.provider_operating_days IS 'Array of operating days arrays, each corresponding to a provider';
COMMENT ON COLUMN transportation_services.advance_booking_hours_array IS 'Array of advance booking hours, each corresponding to a provider';
COMMENT ON COLUMN transportation_services.cancellation_hours_array IS 'Array of cancellation hours, each corresponding to a provider';
