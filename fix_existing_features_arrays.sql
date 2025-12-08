-- Fix existing features arrays with mismatched dimensions
-- This script normalizes all existing features_array data

-- 1. First, let's see what we're working with
-- SELECT id, name, features_array FROM transportation_services WHERE features_array IS NOT NULL AND array_length(features_array, 1) > 0;

-- 2. Create a temporary function to fix existing data
CREATE OR REPLACE FUNCTION fix_existing_features_arrays()
RETURNS void AS $$
DECLARE
    service_record RECORD;
    fixed_features TEXT[][];
    max_length INTEGER;
    normalized_features TEXT[];
BEGIN
    -- Loop through all services that have features arrays
    FOR service_record IN 
        SELECT id, features_array 
        FROM transportation_services 
        WHERE features_array IS NOT NULL 
        AND array_length(features_array, 1) > 0
    LOOP
        -- Find the maximum length of feature arrays for this service
        max_length := 0;
        FOR i IN 1..array_length(service_record.features_array, 1) LOOP
            IF array_length(service_record.features_array[i], 1) > max_length THEN
                max_length := array_length(service_record.features_array[i], 1);
            END IF;
        END LOOP;
        
        -- If no features exist, set to empty array
        IF max_length IS NULL OR max_length = 0 THEN
            fixed_features := ARRAY[]::TEXT[][];
        ELSE
            -- Normalize all feature arrays to the same length
            fixed_features := ARRAY[]::TEXT[][];
            FOR i IN 1..array_length(service_record.features_array, 1) LOOP
                normalized_features := service_record.features_array[i];
                
                -- Pad with empty strings to match max_length
                WHILE array_length(normalized_features, 1) < max_length LOOP
                    normalized_features := array_append(normalized_features, '');
                END LOOP;
                
                fixed_features := array_append(fixed_features, normalized_features);
            END LOOP;
        END IF;
        
        -- Update the service with normalized features
        UPDATE transportation_services 
        SET features_array = fixed_features,
            updated_at = NOW()
        WHERE id = service_record.id;
        
        RAISE NOTICE 'Fixed features array for service %', service_record.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. Run the fix function
SELECT fix_existing_features_arrays();

-- 4. Clean up the temporary function
DROP FUNCTION fix_existing_features_arrays();

-- 5. Verify the fix worked
-- SELECT id, name, features_array FROM transportation_services WHERE features_array IS NOT NULL AND array_length(features_array, 1) > 0;

-- 6. Add a trigger to automatically normalize features arrays on insert/update
CREATE OR REPLACE FUNCTION normalize_features_on_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Normalize features_array if it exists and has data
    IF NEW.features_array IS NOT NULL AND array_length(NEW.features_array, 1) > 0 THEN
        NEW.features_array := normalize_features_array(NEW.features_array);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger to automatically normalize on changes
DROP TRIGGER IF EXISTS normalize_features_trigger ON transportation_services;
CREATE TRIGGER normalize_features_trigger
    BEFORE INSERT OR UPDATE ON transportation_services
    FOR EACH ROW
    EXECUTE FUNCTION normalize_features_on_change();

-- 8. Add helpful comments
COMMENT ON FUNCTION normalize_features_array IS 'Normalizes features arrays to have consistent dimensions by padding with empty strings';
COMMENT ON TRIGGER normalize_features_trigger ON transportation_services IS 'Automatically normalizes features_array dimensions on insert/update';
