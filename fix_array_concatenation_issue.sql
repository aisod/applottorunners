-- Fix for array concatenation dimension mismatch issue
-- The provider_operating_days column is TEXT[][] but we need to handle concatenation properly

-- Fix the add_provider_to_service function to handle 2D array concatenation correctly
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
    current_provider_operating_days TEXT[][];
BEGIN
    -- Get current provider_ids, handling null case
    SELECT COALESCE(provider_ids, '{}'), COALESCE(provider_operating_days, '{}')
    INTO current_provider_ids, current_provider_operating_days
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
        -- Fix: Properly concatenate the 2D array
        provider_operating_days = COALESCE(provider_operating_days, '{}') || ARRAY[ARRAY[p_operating_days]],
        advance_booking_hours_array = COALESCE(advance_booking_hours_array, '{}') || ARRAY[p_advance_booking_hours],
        cancellation_hours_array = COALESCE(cancellation_hours_array, '{}') || ARRAY[p_cancellation_hours],
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Also fix the migration function for existing data
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
            -- Fix: Properly handle 2D array for operating days
            provider_operating_days = CASE 
                WHEN service_record.days_of_week IS NOT NULL AND array_length(service_record.days_of_week, 1) > 0
                THEN ARRAY[ARRAY[service_record.days_of_week]]
                ELSE '{}'::TEXT[][]
            END,
            advance_booking_hours_array = ARRAY[COALESCE(service_record.advance_booking_hours, 1)],
            cancellation_hours_array = ARRAY[COALESCE(service_record.cancellation_hours, 2)]
        WHERE id = service_record.id;
    END LOOP;
    
    RAISE NOTICE 'Migration of existing single providers to arrays completed (fixed 2D array handling)';
END;
$$ LANGUAGE plpgsql;

-- Alternative approach: Convert provider_operating_days to a simpler structure
-- This might be easier to work with - convert to JSONB instead of TEXT[][]

-- Option 1: Add a new JSONB column for operating days
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS provider_operating_days_json JSONB DEFAULT '[]';

-- Create a function to convert between the formats if needed
CREATE OR REPLACE FUNCTION convert_operating_days_to_json()
RETURNS void AS $$
BEGIN
    -- Convert existing TEXT[][] data to JSONB format
    UPDATE transportation_services 
    SET provider_operating_days_json = (
        SELECT COALESCE(
            jsonb_agg(
                CASE 
                    WHEN elem IS NOT NULL 
                    THEN to_jsonb(elem)
                    ELSE '[]'::jsonb
                END
            ), 
            '[]'::jsonb
        )
        FROM unnest(provider_operating_days) AS elem
    )
    WHERE provider_operating_days IS NOT NULL 
    AND array_length(provider_operating_days, 1) > 0;
    
    RAISE NOTICE 'Operating days converted to JSON format';
END;
$$ LANGUAGE plpgsql;

-- Updated add_provider_to_service function using JSONB for operating days
CREATE OR REPLACE FUNCTION add_provider_to_service_v2(
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
    current_operating_days_json JSONB;
BEGIN
    -- Get current provider_ids, handling null case
    SELECT COALESCE(provider_ids, '{}'), COALESCE(provider_operating_days_json, '[]')
    INTO current_provider_ids, current_operating_days_json
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
        -- Use JSONB for operating days - much simpler
        provider_operating_days_json = COALESCE(provider_operating_days_json, '[]') || to_jsonb(p_operating_days),
        advance_booking_hours_array = COALESCE(advance_booking_hours_array, '{}') || ARRAY[p_advance_booking_hours],
        cancellation_hours_array = COALESCE(cancellation_hours_array, '{}') || ARRAY[p_cancellation_hours],
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Execute the conversion
SELECT convert_operating_days_to_json();

-- Comments for documentation
COMMENT ON FUNCTION add_provider_to_service IS 'DEPRECATED: Use add_provider_to_service_v2 for better array handling';
COMMENT ON FUNCTION add_provider_to_service_v2 IS 'Add provider to service using JSONB for operating days (recommended)';
COMMENT ON COLUMN transportation_services.provider_operating_days_json IS 'JSONB array of operating days for each provider (easier to work with than TEXT[][])';
