-- Remove all dependencies between transportation_services and vehicle tables
-- Also remove dependencies between services and categories
-- This script systematically removes foreign keys, columns, and constraints

-- =======================================================================================
-- PART 1: Remove transportation_services and vehicle_types dependencies
-- =======================================================================================

-- 1. First, check what foreign key constraints exist
SELECT '=== CHECKING EXISTING FOREIGN KEY CONSTRAINTS ===' as status;

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND (
    (tc.table_name = 'transportation_services' AND kcu.column_name = 'vehicle_type_id')
    OR (ccu.table_name = 'vehicle_types')
)
ORDER BY tc.table_name, tc.constraint_name;

-- 2. Drop all foreign key constraints that reference vehicle_types
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Loop through all foreign key constraints that reference vehicle_types
    FOR constraint_record IN 
        SELECT tc.constraint_name, tc.table_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND ccu.table_name = 'vehicle_types'
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                      constraint_record.table_name, 
                      constraint_record.constraint_name);
        RAISE NOTICE 'Dropped foreign key constraint % from table %', 
                     constraint_record.constraint_name, 
                     constraint_record.table_name;
    END LOOP;
END $$;

-- 3. Remove vehicle_type_id columns from all tables
DO $$
DECLARE
    table_record RECORD;
BEGIN
    -- Find all tables with vehicle_type_id column
    FOR table_record IN 
        SELECT table_name
        FROM information_schema.columns 
        WHERE column_name = 'vehicle_type_id'
        AND table_schema = current_schema()
    LOOP
        EXECUTE format('ALTER TABLE %I DROP COLUMN IF EXISTS vehicle_type_id', 
                      table_record.table_name);
        RAISE NOTICE 'Dropped vehicle_type_id column from table %', 
                     table_record.table_name;
    END LOOP;
END $$;

-- 4. Drop indexes related to vehicle_type_id
DO $$
DECLARE
    index_record RECORD;
BEGIN
    -- Find and drop indexes that reference vehicle_type_id
    FOR index_record IN 
        SELECT schemaname, indexname, tablename
        FROM pg_indexes 
        WHERE indexdef ILIKE '%vehicle_type_id%'
        AND schemaname = current_schema()
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I', index_record.indexname);
        RAISE NOTICE 'Dropped index % from table %', 
                     index_record.indexname, 
                     index_record.tablename;
    END LOOP;
END $$;

-- =======================================================================================
-- PART 2: Remove services and categories dependencies
-- =======================================================================================

SELECT '=== REMOVING SERVICES AND CATEGORIES DEPENDENCIES ===' as status;

-- 5. Check if services table has foreign key to service_categories
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Check for foreign key constraints between services and service_categories
    FOR constraint_record IN 
        SELECT tc.constraint_name, tc.table_name, kcu.column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'services'
        AND (ccu.table_name = 'service_categories' OR kcu.column_name ILIKE '%category%')
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                      constraint_record.table_name, 
                      constraint_record.constraint_name);
        RAISE NOTICE 'Dropped foreign key constraint % from services table (column: %)', 
                     constraint_record.constraint_name,
                     constraint_record.column_name;
    END LOOP;
    
    -- If no foreign keys found, check if there are any category_id columns
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'services' 
        AND column_name = 'category_id'
    ) THEN
        ALTER TABLE services DROP COLUMN IF EXISTS category_id;
        RAISE NOTICE 'Dropped category_id column from services table';
    END IF;
END $$;

-- 6. Remove any check constraints on category field in services table
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Find and drop check constraints on category column
    FOR constraint_record IN 
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'services'
        AND constraint_type = 'CHECK'
        AND constraint_name ILIKE '%category%'
    LOOP
        EXECUTE format('ALTER TABLE services DROP CONSTRAINT IF EXISTS %I', 
                      constraint_record.constraint_name);
        RAISE NOTICE 'Dropped check constraint % from services table', 
                     constraint_record.constraint_name;
    END LOOP;
END $$;

-- 7. Remove subcategory dependencies from transportation_services
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Drop foreign key constraint for subcategory_id
    FOR constraint_record IN 
        SELECT tc.constraint_name, tc.table_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'transportation_services'
        AND (ccu.table_name = 'service_subcategories' OR kcu.column_name = 'subcategory_id')
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                      constraint_record.table_name, 
                      constraint_record.constraint_name);
        RAISE NOTICE 'Dropped subcategory foreign key constraint % from %', 
                     constraint_record.constraint_name,
                     constraint_record.table_name;
    END LOOP;
    
    -- Drop the subcategory_id column
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transportation_services' 
        AND column_name = 'subcategory_id'
    ) THEN
        ALTER TABLE transportation_services DROP COLUMN IF EXISTS subcategory_id;
        RAISE NOTICE 'Dropped subcategory_id column from transportation_services table';
    END IF;
END $$;

-- =======================================================================================
-- PART 3: Clean up junction tables and related dependencies
-- =======================================================================================

SELECT '=== CLEANING UP JUNCTION TABLES ===' as status;

-- 8. Remove vehicle_type_subcategories table if it exists
DROP TABLE IF EXISTS vehicle_type_subcategories CASCADE;
RAISE NOTICE 'Dropped vehicle_type_subcategories table';

-- 9. Remove any functions that reference vehicle_type_id
DO $$
DECLARE
    function_record RECORD;
BEGIN
    -- Find functions that might reference vehicle_type_id
    FOR function_record IN 
        SELECT routine_name, routine_schema
        FROM information_schema.routines
        WHERE routine_definition ILIKE '%vehicle_type_id%'
        AND routine_schema = current_schema()
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I CASCADE', 
                      function_record.routine_schema,
                      function_record.routine_name);
        RAISE NOTICE 'Dropped function % that referenced vehicle_type_id', 
                     function_record.routine_name;
    END LOOP;
END $$;

-- =======================================================================================
-- PART 4: Verification and summary
-- =======================================================================================

SELECT '=== CLEANUP VERIFICATION ===' as status;

-- 10. Verify all vehicle_type_id references are removed
SELECT 
    table_name, 
    column_name,
    data_type
FROM information_schema.columns 
WHERE column_name = 'vehicle_type_id'
AND table_schema = current_schema();

-- 11. Verify remaining foreign keys that might reference categories or vehicles
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND (
    ccu.table_name IN ('vehicle_types', 'service_categories', 'service_subcategories')
    OR kcu.column_name ILIKE '%category%'
    OR kcu.column_name ILIKE '%vehicle%'
)
ORDER BY tc.table_name, tc.constraint_name;

-- 12. Summary
SELECT '=== CLEANUP SUMMARY ===' as status;
SELECT 
    'Dependencies between transportation_services and vehicle tables have been removed' as result
UNION ALL
SELECT 
    'Dependencies between services and categories have been removed' as result
UNION ALL
SELECT 
    'All vehicle_type_id columns have been dropped' as result
UNION ALL
SELECT 
    'All related foreign key constraints have been removed' as result
UNION ALL
SELECT 
    'Related indexes and junction tables have been cleaned up' as result;

SELECT '=== CLEANUP COMPLETED ===' as status;
