-- Fix for transportation service editing UUID comparison error
-- This script addresses the UUID = UUID[] type mismatch issue

-- First, ensure the array columns exist
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS provider_ids UUID[] DEFAULT '{}';

ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS prices DECIMAL(10,2)[] DEFAULT '{}';

ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS departure_times TIME[] DEFAULT '{}';

ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS check_in_times TIME[] DEFAULT '{}';

ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS provider_operating_days TEXT[][] DEFAULT '{}';

ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS advance_booking_hours_array INTEGER[] DEFAULT '{}';

ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS cancellation_hours_array INTEGER[] DEFAULT '{}';

-- Fix the add_provider_to_service function to handle null arrays properly
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
DECLARE
    current_provider_ids UUID[];
BEGIN
    -- Get current provider_ids, handling null case
    SELECT COALESCE(provider_ids, '{}') INTO current_provider_ids
    FROM transportation_services 
    WHERE id = p_service_id;
    
    -- Check if provider already exists for this service
    IF p_provider_id = ANY(current_provider_ids) THEN
        RAISE EXCEPTION 'Provider already exists for this service';
    END IF;

    -- Add provider data to arrays
    UPDATE transportation_services 
    SET 
        provider_ids = COALESCE(provider_ids, '{}') || ARRAY[p_provider_id],
        prices = COALESCE(prices, '{}') || ARRAY[p_price],
        departure_times = COALESCE(departure_times, '{}') || ARRAY[p_departure_time],
        check_in_times = COALESCE(check_in_times, '{}') || ARRAY[p_check_in_time],
        provider_operating_days = COALESCE(provider_operating_days, '{}') || ARRAY[p_operating_days],
        advance_booking_hours_array = COALESCE(advance_booking_hours_array, '{}') || ARRAY[p_advance_booking_hours],
        cancellation_hours_array = COALESCE(cancellation_hours_array, '{}') || ARRAY[p_cancellation_hours],
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Fix the remove_provider_from_service function
CREATE OR REPLACE FUNCTION remove_provider_from_service(
    p_service_id UUID,
    p_provider_id UUID
)
RETURNS boolean AS $$
DECLARE
    provider_index INTEGER;
    current_provider_ids UUID[];
BEGIN
    -- Get current provider_ids, handling null case
    SELECT COALESCE(provider_ids, '{}') INTO current_provider_ids
    FROM transportation_services 
    WHERE id = p_service_id;
    
    -- Find the index of the provider
    SELECT array_position(current_provider_ids, p_provider_id) INTO provider_index;

    IF provider_index IS NULL THEN
        RAISE EXCEPTION 'Provider not found for this service';
    END IF;

    -- Remove provider data from all arrays at the same index
    UPDATE transportation_services 
    SET 
        provider_ids = array_remove(COALESCE(provider_ids, '{}'), p_provider_id),
        prices = (
            SELECT COALESCE(array_agg(val ORDER BY ordinality), '{}')
            FROM unnest(COALESCE(prices, '{}')) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        departure_times = (
            SELECT COALESCE(array_agg(val ORDER BY ordinality), '{}')
            FROM unnest(COALESCE(departure_times, '{}')) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        check_in_times = (
            SELECT COALESCE(array_agg(val ORDER BY ordinality), '{}')
            FROM unnest(COALESCE(check_in_times, '{}')) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        provider_operating_days = (
            SELECT COALESCE(array_agg(val ORDER BY ordinality), '{}')
            FROM unnest(COALESCE(provider_operating_days, '{}')) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        advance_booking_hours_array = (
            SELECT COALESCE(array_agg(val ORDER BY ordinality), '{}')
            FROM unnest(COALESCE(advance_booking_hours_array, '{}')) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        cancellation_hours_array = (
            SELECT COALESCE(array_agg(val ORDER BY ordinality), '{}')
            FROM unnest(COALESCE(cancellation_hours_array, '{}')) WITH ORDINALITY AS t(val, ordinality)
            WHERE ordinality != provider_index
        ),
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Fix the update_service_provider function
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
    current_provider_ids UUID[];
BEGIN
    -- Get current provider_ids, handling null case
    SELECT COALESCE(provider_ids, '{}') INTO current_provider_ids
    FROM transportation_services 
    WHERE id = p_service_id;
    
    -- Find the index of the provider
    SELECT array_position(current_provider_ids, p_provider_id) INTO provider_index;

    IF provider_index IS NULL THEN
        RAISE EXCEPTION 'Provider not found for this service';
    END IF;

    -- Get current arrays
    SELECT COALESCE(prices, '{}'), COALESCE(departure_times, '{}'), COALESCE(check_in_times, '{}'), 
           COALESCE(provider_operating_days, '{}'), COALESCE(advance_booking_hours_array, '{}'), 
           COALESCE(cancellation_hours_array, '{}')
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

-- Migrate existing single-provider data to arrays if they exist
CREATE OR REPLACE FUNCTION migrate_existing_single_providers()
RETURNS void AS $$
DECLARE
    service_record RECORD;
BEGIN
    -- Loop through existing transportation services that have single provider data but empty arrays
    FOR service_record IN 
        SELECT id, provider_id, price, departure_time, check_in_time, 
               days_of_week, advance_booking_hours, cancellation_hours
        FROM transportation_services 
        WHERE provider_id IS NOT NULL 
        AND (provider_ids IS NULL OR array_length(provider_ids, 1) IS NULL OR array_length(provider_ids, 1) = 0)
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
    
    RAISE NOTICE 'Migration of existing single providers to arrays completed';
END;
$$ LANGUAGE plpgsql;

-- Execute the migration
SELECT migrate_existing_single_providers();

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_transportation_services_provider_ids ON transportation_services USING GIN(provider_ids);

-- Add helpful comments
COMMENT ON FUNCTION add_provider_to_service IS 'Adds a provider to a transportation service using array columns. Handles null arrays properly.';
COMMENT ON FUNCTION remove_provider_from_service IS 'Removes a provider from a transportation service array columns. Handles null arrays properly.';
COMMENT ON FUNCTION update_service_provider IS 'Updates provider data in transportation service array columns. Handles null arrays properly.';
