-- Update the add_provider_to_service function to also update provider_names
CREATE OR REPLACE FUNCTION add_provider_to_service(
    p_service_id UUID,
    p_provider_id UUID,
    p_price DECIMAL,
    p_departure_time TIME,
    p_check_in_time TIME DEFAULT NULL,
    p_operating_days INTEGER[] DEFAULT '{1}',
    p_advance_booking_hours INTEGER DEFAULT 1,
    p_cancellation_hours INTEGER DEFAULT 2
) RETURNS VOID AS $$
DECLARE
    current_provider_ids UUID[];
    current_provider_names TEXT[];
    provider_name TEXT;
BEGIN
    -- Get current provider data
    SELECT COALESCE(provider_ids, '{}'), COALESCE(provider_names, '{}')
    INTO current_provider_ids, current_provider_names
    FROM transportation_services
    WHERE id = p_service_id;
    
    -- Get provider name
    SELECT name INTO provider_name
    FROM service_providers
    WHERE id = p_provider_id;
    
    -- Add new provider data to arrays
    UPDATE transportation_services
    SET 
        provider_ids = current_provider_ids || p_provider_id,
        prices = COALESCE(prices, '{}') || p_price,
        departure_times = COALESCE(departure_times, '{}') || p_departure_time,
        check_in_times = COALESCE(check_in_times, '{}') || p_check_in_time,
        provider_operating_days = COALESCE(provider_operating_days, '{}') || p_operating_days,
        advance_booking_hours_array = COALESCE(advance_booking_hours_array, '{}') || p_advance_booking_hours,
        cancellation_hours_array = COALESCE(cancellation_hours_array, '{}') || p_cancellation_hours,
        provider_names = current_provider_names || COALESCE(provider_name, 'Unknown Provider')
    WHERE id = p_service_id;
    
    RAISE NOTICE 'Added provider % to service %', provider_name, p_service_id;
END;
$$ LANGUAGE plpgsql;

-- Update the remove_provider_from_service function to also update provider_names
CREATE OR REPLACE FUNCTION remove_provider_from_service(
    p_service_id UUID,
    p_provider_id UUID
) RETURNS VOID AS $$
DECLARE
    current_provider_ids UUID[];
    current_provider_names TEXT[];
    provider_index INTEGER;
    provider_name TEXT;
BEGIN
    -- Get current provider data
    SELECT COALESCE(provider_ids, '{}'), COALESCE(provider_names, '{}')
    INTO current_provider_ids, current_provider_names
    FROM transportation_services
    WHERE id = p_service_id;
    
    -- Find the index of the provider to remove
    SELECT array_position(current_provider_ids, p_provider_id) INTO provider_index;
    
    -- Get provider name for logging
    SELECT name INTO provider_name
    FROM service_providers
    WHERE id = p_provider_id;
    
    IF provider_index IS NOT NULL THEN
        -- Remove provider from all arrays
        UPDATE transportation_services
        SET 
            provider_ids = array_remove(current_provider_ids, p_provider_id),
            prices = array_remove(prices, prices[provider_index]),
            departure_times = array_remove(departure_times, departure_times[provider_index]),
            check_in_times = array_remove(check_in_times, check_in_times[provider_index]),
            provider_operating_days = array_remove(provider_operating_days, provider_operating_days[provider_index]),
            advance_booking_hours_array = array_remove(advance_booking_hours_array, advance_booking_hours_array[provider_index]),
            cancellation_hours_array = array_remove(cancellation_hours_array, cancellation_hours_array[provider_index]),
            provider_names = array_remove(current_provider_names, current_provider_names[provider_index])
        WHERE id = p_service_id;
        
        RAISE NOTICE 'Removed provider % from service %', provider_name, p_service_id;
    ELSE
        RAISE NOTICE 'Provider % not found in service %', p_provider_id, p_service_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
