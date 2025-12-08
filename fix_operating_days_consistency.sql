-- Fix operating days consistency between createTransportationService and addProviderToService
-- The issue: createTransportationService stores operating days as List<List<int>> (2D array)
-- But addProviderToService tries to add List<int> (1D array) to it, causing dimension mismatch

-- Updated add_provider_to_service function with proper array handling
CREATE OR REPLACE FUNCTION add_provider_to_service(
    p_service_id UUID,
    p_provider_id UUID,
    p_price DECIMAL(10,2),
    p_departure_time TIME,
    p_check_in_time TIME DEFAULT NULL,
    p_operating_days INTEGER[] DEFAULT '{}', -- Changed to INTEGER[] to match conversion
    p_advance_booking_hours INTEGER DEFAULT 1,
    p_cancellation_hours INTEGER DEFAULT 2
)
RETURNS boolean AS $$
DECLARE
    current_provider_ids UUID[];
    current_provider_operating_days INTEGER[][];
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
        -- Fix: Wrap the 1D array in another array to make it 2D like during creation
        provider_operating_days = COALESCE(provider_operating_days, '{}') || ARRAY[ARRAY[p_operating_days]],
        advance_booking_hours_array = COALESCE(advance_booking_hours_array, '{}') || ARRAY[p_advance_booking_hours],
        cancellation_hours_array = COALESCE(cancellation_hours_array, '{}') || ARRAY[p_cancellation_hours],
        updated_at = NOW()
    WHERE id = p_service_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Also update the migration function to handle the correct data type
CREATE OR REPLACE FUNCTION migrate_existing_single_providers()
RETURNS void AS $$
DECLARE
    service_record RECORD;
    operating_days_as_integers INTEGER[];
BEGIN
    -- Loop through existing transportation services that have single provider data but empty arrays
    FOR service_record IN 
        SELECT id, provider_id, price, departure_time, check_in_time, 
               days_of_week, advance_booking_hours, cancellation_hours
        FROM transportation_services 
        WHERE provider_id IS NOT NULL 
        AND (provider_ids IS NULL OR array_length(provider_ids, 1) IS NULL OR array_length(provider_ids, 1) = 0)
    LOOP
        -- Convert TEXT[] days_of_week to INTEGER[] if it exists
        IF service_record.days_of_week IS NOT NULL AND array_length(service_record.days_of_week, 1) > 0 THEN
            -- Convert day names to integers (assuming they're stored as day names)
            SELECT array_agg(
                CASE LOWER(day)
                    WHEN 'monday' THEN 1
                    WHEN 'tuesday' THEN 2
                    WHEN 'wednesday' THEN 3
                    WHEN 'thursday' THEN 4
                    WHEN 'friday' THEN 5
                    WHEN 'saturday' THEN 6
                    WHEN 'sunday' THEN 7
                    ELSE day::INTEGER -- If already integer
                END
            ) INTO operating_days_as_integers
            FROM unnest(service_record.days_of_week) AS day;
        ELSE
            operating_days_as_integers := '{}';
        END IF;

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
                WHEN operating_days_as_integers IS NOT NULL AND array_length(operating_days_as_integers, 1) > 0
                THEN ARRAY[ARRAY[operating_days_as_integers]]
                ELSE '{}'::INTEGER[][]
            END,
            advance_booking_hours_array = ARRAY[COALESCE(service_record.advance_booking_hours, 1)],
            cancellation_hours_array = ARRAY[COALESCE(service_record.cancellation_hours, 2)]
        WHERE id = service_record.id;
    END LOOP;
    
    RAISE NOTICE 'Migration of existing single providers to arrays completed (fixed operating days consistency)';
END;
$$ LANGUAGE plpgsql;

-- Update the provider_operating_days column to use INTEGER[][] instead of TEXT[][] for consistency
-- First, let's create a backup column
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS provider_operating_days_backup TEXT[][];

-- Backup existing data
UPDATE transportation_services 
SET provider_operating_days_backup = provider_operating_days
WHERE provider_operating_days IS NOT NULL;

-- Drop the old column and recreate with correct type
ALTER TABLE transportation_services DROP COLUMN IF EXISTS provider_operating_days;
ALTER TABLE transportation_services 
ADD COLUMN provider_operating_days INTEGER[][] DEFAULT '{}';

-- Convert data from backup if it exists
CREATE OR REPLACE FUNCTION restore_operating_days_as_integers()
RETURNS void AS $$
DECLARE
    service_record RECORD;
    converted_days INTEGER[][];
BEGIN
    FOR service_record IN 
        SELECT id, provider_operating_days_backup
        FROM transportation_services 
        WHERE provider_operating_days_backup IS NOT NULL 
        AND array_length(provider_operating_days_backup, 1) > 0
    LOOP
        -- Convert each TEXT[] to INTEGER[] in the 2D array
        SELECT array_agg(
            (SELECT array_agg(
                CASE 
                    WHEN day ~ '^\d+$' THEN day::INTEGER -- If it's already a number
                    ELSE CASE LOWER(day)
                        WHEN 'monday' THEN 1
                        WHEN 'tuesday' THEN 2
                        WHEN 'wednesday' THEN 3
                        WHEN 'thursday' THEN 4
                        WHEN 'friday' THEN 5
                        WHEN 'saturday' THEN 6
                        WHEN 'sunday' THEN 7
                        ELSE 1 -- Default to Monday if unknown
                    END
                END
            ) FROM unnest(provider_days) AS day)
        ) INTO converted_days
        FROM unnest(service_record.provider_operating_days_backup) AS provider_days;

        UPDATE transportation_services 
        SET provider_operating_days = converted_days
        WHERE id = service_record.id;
    END LOOP;
    
    RAISE NOTICE 'Operating days converted from TEXT[][] to INTEGER[][]';
END;
$$ LANGUAGE plpgsql;

-- Execute the conversion
SELECT restore_operating_days_as_integers();

-- Execute the migration for any remaining single providers
SELECT migrate_existing_single_providers();

-- Clean up backup column
ALTER TABLE transportation_services DROP COLUMN IF EXISTS provider_operating_days_backup;

-- Update the view to work with INTEGER[][] 
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

-- Add helpful comments
COMMENT ON FUNCTION add_provider_to_service IS 'Add provider to service - now handles operating days as INTEGER[] consistently with createTransportationService';
COMMENT ON COLUMN transportation_services.provider_operating_days IS 'Array of operating days arrays (INTEGER[][]), each provider has INTEGER[] of day numbers (1=Monday, 7=Sunday)';
