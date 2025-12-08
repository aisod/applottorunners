-- Quick Database Status Check
-- Run this in your Supabase SQL Editor to see what's missing

-- 1. Check which tables exist
SELECT '=== CHECKING TABLE EXISTENCE ===' as status;

SELECT 
    tablename,
    CASE 
        WHEN tablename IN ('transportation_services', 'service_providers', 'service_routes') 
        THEN '🔴 REQUIRED'
        ELSE '🟡 OPTIONAL'
    END as importance
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('transportation_services', 'service_providers', 'service_routes', 'routes')
ORDER BY importance DESC, tablename;

-- 2. Count records in existing tables
SELECT '=== RECORD COUNTS ===' as status;

-- Check transportation_services
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transportation_services') THEN
        PERFORM 1;
        RAISE NOTICE 'transportation_services: % records', (SELECT COUNT(*) FROM transportation_services);
    ELSE
        RAISE NOTICE 'transportation_services: TABLE DOES NOT EXIST';
    END IF;
END $$;

-- Check service_providers
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_providers') THEN
        PERFORM 1;
        RAISE NOTICE 'service_providers: % records', (SELECT COUNT(*) FROM service_providers);
    ELSE
        RAISE NOTICE 'service_providers: TABLE DOES NOT EXIST';
    END IF;
END $$;

-- Check service_routes
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_routes') THEN
        PERFORM 1;
        RAISE NOTICE 'service_routes: % records', (SELECT COUNT(*) FROM service_routes);
    ELSE
        RAISE NOTICE 'service_routes: TABLE DOES NOT EXIST';
    END IF;
END $$;

-- 3. Show sample data if tables exist
SELECT '=== SAMPLE DATA ===' as status;

-- Transportation services
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transportation_services') THEN
        IF (SELECT COUNT(*) FROM transportation_services) > 0 THEN
            RAISE NOTICE 'Sample transportation services:';
            PERFORM 1; -- This will allow the following query to run
        END IF;
    END IF;
END $$;

-- Only run if table exists and has data
SELECT 
    name, 
    is_active,
    provider_id,
    route_id
FROM transportation_services 
WHERE EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transportation_services')
LIMIT 3;

-- 4. Recommendations
SELECT '=== RECOMMENDATIONS ===' as status;

DO $$
DECLARE
    has_transport_services BOOLEAN := FALSE;
    has_service_providers BOOLEAN := FALSE;
    has_service_routes BOOLEAN := FALSE;
BEGIN
    -- Check what exists
    has_transport_services := EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transportation_services');
    has_service_providers := EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_providers');
    has_service_routes := EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_routes');
    
    IF NOT has_transport_services THEN
        RAISE NOTICE '❌ CRITICAL: transportation_services table missing. Run transportation_system.sql first!';
    END IF;
    
    IF NOT has_service_providers THEN
        RAISE NOTICE '❌ CRITICAL: service_providers table missing. Run transportation_system.sql first!';
    END IF;
    
    IF NOT has_service_routes THEN
        RAISE NOTICE '❌ CRITICAL: service_routes table missing. Run create_service_routes_table.sql!';
    END IF;
    
    IF has_transport_services AND has_service_providers AND has_service_routes THEN
        RAISE NOTICE '✅ All required tables exist. Check if they have data.';
    END IF;
END $$;
