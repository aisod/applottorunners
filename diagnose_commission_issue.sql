-- Diagnostic Script for Commission Accounting Issues
-- Run this to understand why provider accounting might show 0

-- ============================================================================
-- 1. CHECK IF ERRANDS HAVE RUNNER ASSIGNMENTS
-- ============================================================================
SELECT 
    '=== ERRANDS DIAGNOSTIC ===' as section,
    '' as info;

SELECT 
    status,
    COUNT(*) as count,
    COUNT(runner_id) as with_runner,
    SUM(price_amount) as total_amount
FROM errands
GROUP BY status
ORDER BY status;

-- Show sample errands with runners
SELECT 
    'Sample Errands with Runners:' as section,
    '' as info;
    
SELECT 
    e.id,
    e.title,
    e.status,
    e.price_amount,
    u.full_name as runner_name,
    u.email as runner_email
FROM errands e
LEFT JOIN users u ON e.runner_id = u.id
WHERE e.runner_id IS NOT NULL
LIMIT 5;

-- ============================================================================
-- 2. CHECK IF TRANSPORTATION BOOKINGS HAVE DRIVER ASSIGNMENTS
-- ============================================================================
SELECT 
    '=== TRANSPORTATION BOOKINGS DIAGNOSTIC ===' as section,
    '' as info;

SELECT 
    status,
    COUNT(*) as count,
    COUNT(driver_id) as with_driver,
    SUM(COALESCE(final_price, estimated_price, 0)) as total_amount
FROM transportation_bookings
GROUP BY status
ORDER BY status;

-- Show sample transportation bookings
SELECT 
    'Sample Transportation Bookings with Drivers:' as section,
    '' as info;

SELECT 
    tb.id,
    tb.pickup_location,
    tb.dropoff_location,
    tb.status,
    COALESCE(tb.final_price, tb.estimated_price) as price,
    u.full_name as driver_name,
    u.email as driver_email
FROM transportation_bookings tb
LEFT JOIN users u ON tb.driver_id = u.id
WHERE tb.driver_id IS NOT NULL
LIMIT 5;

-- ============================================================================
-- 3. CHECK CONTRACT BOOKINGS
-- ============================================================================
SELECT 
    '=== CONTRACT BOOKINGS DIAGNOSTIC ===' as section,
    '' as info;

SELECT 
    status,
    COUNT(*) as count,
    COUNT(COALESCE(runner_id, driver_id)) as with_runner,
    SUM(COALESCE(final_price, estimated_price, 0)) as total_amount
FROM contract_bookings
GROUP BY status
ORDER BY status;

-- ============================================================================
-- 4. CHECK BUS SERVICE BOOKINGS
-- ============================================================================
SELECT 
    '=== BUS SERVICE BOOKINGS DIAGNOSTIC ===' as section,
    '' as info;

SELECT 
    status,
    COUNT(*) as count,
    COUNT(runner_id) as with_runner,
    SUM(COALESCE(final_price, estimated_price, 0)) as total_amount
FROM bus_service_bookings
GROUP BY status
ORDER BY status;

-- ============================================================================
-- 5. CHECK IF USERS ARE MARKED AS RUNNERS
-- ============================================================================
SELECT 
    '=== RUNNERS/PROVIDERS DIAGNOSTIC ===' as section,
    '' as info;

SELECT 
    user_type,
    is_verified,
    COUNT(*) as count
FROM users
WHERE user_type = 'runner' OR is_verified = true
GROUP BY user_type, is_verified;

-- Show sample runners
SELECT 
    'Sample Runners:' as section,
    '' as info;

SELECT 
    id,
    full_name,
    email,
    user_type,
    is_verified,
    has_vehicle
FROM users
WHERE user_type = 'runner' OR is_verified = true
LIMIT 5;

-- ============================================================================
-- 6. CHECK PAYMENTS TABLE
-- ============================================================================
SELECT 
    '=== PAYMENTS TABLE DIAGNOSTIC ===' as section,
    '' as info;

SELECT 
    status,
    COUNT(*) as count,
    COUNT(runner_id) as with_runner,
    SUM(amount) as total_amount,
    SUM(company_commission) as commission,
    SUM(runner_earnings) as earnings
FROM payments
GROUP BY status;

-- ============================================================================
-- 7. CHECK IF COMMISSION COLUMNS EXIST AND ARE POPULATED
-- ============================================================================
SELECT 
    '=== COMMISSION FIELDS CHECK ===' as section,
    '' as info;

-- Check payments commission
SELECT 
    'Payments with Commission' as table_name,
    COUNT(*) as total,
    COUNT(CASE WHEN company_commission > 0 THEN 1 END) as with_commission,
    AVG(CASE WHEN company_commission > 0 THEN commission_rate END) as avg_rate
FROM payments
WHERE runner_id IS NOT NULL;

-- Check transportation commission
SELECT 
    'Transportation with Commission' as table_name,
    COUNT(*) as total,
    COUNT(CASE WHEN company_commission > 0 THEN 1 END) as with_commission,
    AVG(CASE WHEN company_commission > 0 THEN commission_rate END) as avg_rate
FROM transportation_bookings
WHERE driver_id IS NOT NULL;

-- ============================================================================
-- 8. TEST THE VIEW DIRECTLY
-- ============================================================================
SELECT 
    '=== RUNNER EARNINGS SUMMARY VIEW TEST ===' as section,
    '' as info;

SELECT * FROM runner_earnings_summary
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================================
-- 9. RAW DATA CHECK - WHAT THE VIEW SHOULD SEE
-- ============================================================================
SELECT 
    '=== RAW DATA FOR VIEW ===' as section,
    '' as info;

-- Manual query to replicate what the view does
SELECT 
    u.id,
    u.full_name,
    u.email,
    COUNT(p.id) as payment_count,
    SUM(p.amount) as payment_total,
    SUM(p.company_commission) as payment_commission
FROM users u
LEFT JOIN payments p ON u.id = p.runner_id AND p.status = 'completed'
WHERE u.user_type = 'runner' OR u.is_verified = true
GROUP BY u.id, u.full_name, u.email
HAVING COUNT(p.id) > 0
ORDER BY payment_total DESC
LIMIT 5;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT 
    '=== SUMMARY ===' as section,
    '' as info;

SELECT 
    'Total Runners' as metric,
    COUNT(*) as value
FROM users
WHERE user_type = 'runner' OR is_verified = true
UNION ALL
SELECT 
    'Completed Errands with Runner' as metric,
    COUNT(*) as value
FROM errands
WHERE status = 'completed' AND runner_id IS NOT NULL
UNION ALL
SELECT 
    'Transportation Bookings with Driver' as metric,
    COUNT(*) as value
FROM transportation_bookings
WHERE COALESCE(driver_id, runner_id) IS NOT NULL
UNION ALL
SELECT 
    'Completed Payments' as metric,
    COUNT(*) as value
FROM payments
WHERE status = 'completed' AND runner_id IS NOT NULL;

