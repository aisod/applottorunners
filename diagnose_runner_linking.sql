-- ============================================================================
-- DIAGNOSE RUNNER LINKING ISSUE
-- Check if bookings have runner_id/driver_id populated
-- ============================================================================

-- TEST 1: Check transportation_bookings
SELECT 
    '=== TRANSPORTATION BOOKINGS ===' as test_section,
    COUNT(*) as total_bookings,
    COUNT(driver_id) as bookings_with_driver_id,
    COUNT(runner_id) as bookings_with_runner_id,
    COUNT(*) - COUNT(driver_id) - COUNT(runner_id) as bookings_without_runners
FROM transportation_bookings;

-- Sample transportation bookings
SELECT 
    id, 
    user_id, 
    driver_id, 
    runner_id,
    status,
    estimated_price,
    pickup_location
FROM transportation_bookings 
LIMIT 5;

-- TEST 2: Check bus_service_bookings
SELECT 
    '=== BUS SERVICE BOOKINGS ===' as test_section,
    COUNT(*) as total_bookings,
    COUNT(runner_id) as bookings_with_runner_id,
    COUNT(*) - COUNT(runner_id) as bookings_without_runner_id
FROM bus_service_bookings;

-- Sample bus bookings
SELECT 
    id, 
    user_id, 
    runner_id,
    status,
    estimated_price,
    pickup_location
FROM bus_service_bookings 
LIMIT 5;

-- TEST 3: Check contract_bookings
SELECT 
    '=== CONTRACT BOOKINGS ===' as test_section,
    COUNT(*) as total_bookings,
    COUNT(driver_id) as bookings_with_driver_id,
    COUNT(runner_id) as bookings_with_runner_id
FROM contract_bookings;

-- TEST 4: Check payments (errands)
SELECT 
    '=== PAYMENTS/ERRANDS ===' as test_section,
    COUNT(*) as total_payments,
    COUNT(runner_id) as payments_with_runner_id,
    COUNT(*) - COUNT(runner_id) as payments_without_runner_id
FROM payments;

-- TEST 5: Check users/runners
SELECT 
    '=== USERS/RUNNERS ===' as test_section,
    COUNT(*) as total_users,
    COUNT(CASE WHEN user_type = 'runner' THEN 1 END) as users_marked_as_runner,
    COUNT(CASE WHEN is_verified = true THEN 1 END) as verified_users
FROM users;

-- Show some runners
SELECT id, full_name, email, user_type, is_verified
FROM users
WHERE user_type = 'runner' OR is_verified = true
LIMIT 10;

-- TEST 6: Check transportation_services and their providers
SELECT 
    '=== TRANSPORTATION SERVICES ===' as test_section,
    COUNT(*) as total_services,
    COUNT(provider_id) as services_with_provider_id
FROM transportation_services;

-- Sample services with providers
SELECT 
    id, 
    name, 
    provider_id,
    provider_names
FROM transportation_services 
LIMIT 5;

-- TEST 7: Try to link bookings to providers via services
SELECT 
    '=== BOOKING TO PROVIDER LINK TEST ===' as test_section,
    COUNT(DISTINCT tb.id) as bookings,
    COUNT(DISTINCT ts.provider_id) as unique_providers
FROM transportation_bookings tb
LEFT JOIN transportation_services ts ON tb.service_id = ts.id
WHERE ts.provider_id IS NOT NULL;

-- Show sample booking -> service -> provider chain
SELECT 
    tb.id as booking_id,
    tb.status,
    tb.driver_id,
    tb.runner_id,
    ts.id as service_id,
    ts.name as service_name,
    ts.provider_id,
    ts.provider_names
FROM transportation_bookings tb
LEFT JOIN transportation_services ts ON tb.service_id = ts.id
LIMIT 10;

