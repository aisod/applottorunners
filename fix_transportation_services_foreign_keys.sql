-- Fix foreign key relationships for transportation_services
-- Run this after creating the service_routes table

-- 1. Check current foreign key constraints
SELECT '=== CURRENT FOREIGN KEY CONSTRAINTS ===' as status;

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
AND tc.table_name = 'transportation_services';

-- 2. Add foreign key constraint for route_id if it doesn't exist
DO $$
BEGIN
    -- Check if the foreign key constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'transportation_services_route_id_fkey'
        AND table_name = 'transportation_services'
    ) THEN
        -- Add the foreign key constraint
        ALTER TABLE transportation_services 
        ADD CONSTRAINT transportation_services_route_id_fkey 
        FOREIGN KEY (route_id) REFERENCES service_routes(id) ON DELETE SET NULL;
        
        RAISE NOTICE 'Added foreign key constraint: transportation_services.route_id -> service_routes.id';
    ELSE
        RAISE NOTICE 'Foreign key constraint already exists';
    END IF;
END $$;

-- 3. Ensure the route_id column exists and has the right type
DO $$
BEGIN
    -- Check if route_id column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transportation_services' 
        AND column_name = 'route_id'
    ) THEN
        -- Add the route_id column
        ALTER TABLE transportation_services 
        ADD COLUMN route_id UUID REFERENCES service_routes(id);
        
        RAISE NOTICE 'Added route_id column to transportation_services table';
    ELSE
        RAISE NOTICE 'route_id column already exists';
    END IF;
END $$;

-- 4. Update existing transportation_services to have route_id values
-- This will link services to appropriate routes based on their names
UPDATE transportation_services 
SET route_id = (
    SELECT sr.id 
    FROM service_routes sr 
    WHERE LOWER(sr.route_name) LIKE '%' || LOWER(transportation_services.name) || '%'
    OR LOWER(transportation_services.name) LIKE '%' || LOWER(sr.route_name) || '%'
    LIMIT 1
)
WHERE route_id IS NULL;

-- 5. Show the updated relationships
SELECT '=== UPDATED RELATIONSHIPS ===' as status;

SELECT 
    ts.id,
    ts.name as service_name,
    ts.route_id,
    sr.route_name,
    sr.from_location,
    sr.to_location,
    CASE 
        WHEN ts.route_id IS NOT NULL THEN '✅ Linked'
        ELSE '❌ No Route'
    END as status
FROM transportation_services ts
LEFT JOIN service_routes sr ON ts.route_id = sr.id
ORDER BY ts.name;

-- 6. Verify the foreign key constraint works
SELECT '=== FOREIGN KEY VERIFICATION ===' as status;

-- Test inserting a service with a valid route_id
DO $$
DECLARE
    test_route_id UUID;
    test_service_id UUID;
BEGIN
    -- Get a valid route_id
    SELECT id INTO test_route_id FROM service_routes LIMIT 1;
    
    IF test_route_id IS NOT NULL THEN
        -- Try to insert a test service
        INSERT INTO transportation_services (name, description, route_id, is_active) 
        VALUES ('Test Service', 'Test service for verification', test_route_id, true)
        RETURNING id INTO test_service_id;
        
        RAISE NOTICE '✅ Successfully inserted test service with route_id: %', test_service_id;
        
        -- Clean up the test service
        DELETE FROM transportation_services WHERE id = test_service_id;
        RAISE NOTICE '✅ Test service cleaned up';
    ELSE
        RAISE NOTICE '❌ No routes available for testing';
    END IF;
END $$;

-- 7. Final verification
SELECT '=== FINAL VERIFICATION ===' as status;

-- Count services with and without routes
SELECT 
    'transportation_services' as table_name,
    COUNT(*) as total_services,
    COUNT(route_id) as services_with_routes,
    COUNT(*) - COUNT(route_id) as services_without_routes
FROM transportation_services;

-- Show sample of linked services
SELECT 
    ts.name as service_name,
    sr.route_name,
    sr.from_location,
    sr.to_location,
    sr.distance_km
FROM transportation_services ts
INNER JOIN service_routes sr ON ts.route_id = sr.id
WHERE ts.is_active = true
ORDER BY ts.name
LIMIT 5;
