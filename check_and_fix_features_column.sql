-- Check and fix features_array column issues
-- This script will diagnose and fix the array_length error

-- Step 1: Check if features_array column exists and its type
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'transportation_services' 
AND column_name = 'features_array';

-- Step 2: Check current data in features_array column (if it exists)
SELECT 
    id, 
    name, 
    features_array,
    pg_typeof(features_array) as column_type
FROM transportation_services 
WHERE features_array IS NOT NULL 
LIMIT 5;

-- Step 3: If column doesn't exist or has wrong type, fix it
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
        -- Check if column has wrong type
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'transportation_services' 
            AND column_name = 'features_array'
            AND data_type != 'ARRAY'
        ) THEN
            -- Drop and recreate with correct type
            ALTER TABLE transportation_services DROP COLUMN features_array;
            ALTER TABLE transportation_services 
            ADD COLUMN features_array TEXT[][] DEFAULT '{}';
            
            RAISE NOTICE 'Recreated features_array column with correct type';
        ELSE
            RAISE NOTICE 'features_array column already exists with correct type';
        END IF;
    END IF;
END $$;

-- Step 4: Verify the column is now correct
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'transportation_services' 
AND column_name = 'features_array';

-- Step 5: Test array_length function on the column
SELECT 
    id, 
    name, 
    features_array,
    array_length(features_array, 1) as array_length_dim1,
    array_length(features_array, 2) as array_length_dim2
FROM transportation_services 
WHERE features_array IS NOT NULL 
LIMIT 3;

-- Step 6: If there are any malformed arrays, fix them
UPDATE transportation_services 
SET features_array = ARRAY[]::TEXT[][]
WHERE features_array IS NULL 
   OR pg_typeof(features_array) != 'text[][]'::regtype;

-- Step 7: Create a simple test to verify everything works
DO $$
DECLARE
    test_array TEXT[][];
BEGIN
    -- Test creating a simple features array
    test_array := ARRAY[ARRAY['AC', 'WiFi'], ARRAY['AC', 'WiFi', 'Luggage']];
    
    -- Test array_length function
    IF array_length(test_array, 1) = 2 AND array_length(test_array, 2) = 3 THEN
        RAISE NOTICE '✅ Array functions working correctly';
    ELSE
        RAISE NOTICE '❌ Array functions not working correctly';
    END IF;
END $$;
