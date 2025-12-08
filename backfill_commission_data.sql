-- Backfill Commission Data for Existing Bookings
-- This script calculates and populates commission data for all existing bookings
-- Run this AFTER running add_commission_tracking.sql

-- ============================================================================
-- UPDATE PAYMENTS TABLE (Errands)
-- ============================================================================
UPDATE payments
SET 
    company_commission = ROUND(amount * 0.3333, 2),
    runner_earnings = ROUND(amount * 0.6667, 2),
    commission_rate = 33.33
WHERE status = 'completed'
  AND runner_id IS NOT NULL
  AND (company_commission IS NULL OR company_commission = 0);

-- ============================================================================
-- UPDATE TRANSPORTATION_BOOKINGS TABLE
-- ============================================================================
UPDATE transportation_bookings
SET 
    company_commission = ROUND(COALESCE(final_price, estimated_price, 0) * 0.3333, 2),
    runner_earnings = ROUND(COALESCE(final_price, estimated_price, 0) * 0.6667, 2),
    commission_rate = 33.33
WHERE status IN ('completed', 'confirmed', 'in_progress', 'accepted')
  AND COALESCE(driver_id, runner_id) IS NOT NULL
  AND COALESCE(final_price, estimated_price, 0) > 0
  AND (company_commission IS NULL OR company_commission = 0);

-- ============================================================================
-- UPDATE CONTRACT_BOOKINGS TABLE
-- ============================================================================
UPDATE contract_bookings
SET 
    company_commission = ROUND(COALESCE(final_price, estimated_price, 0) * 0.3333, 2),
    runner_earnings = ROUND(COALESCE(final_price, estimated_price, 0) * 0.6667, 2),
    commission_rate = 33.33
WHERE status IN ('completed', 'active', 'confirmed')
  AND COALESCE(runner_id, driver_id) IS NOT NULL
  AND COALESCE(final_price, estimated_price, 0) > 0
  AND (company_commission IS NULL OR company_commission = 0);

-- ============================================================================
-- UPDATE BUS_SERVICE_BOOKINGS TABLE
-- ============================================================================
UPDATE bus_service_bookings
SET 
    company_commission = ROUND(COALESCE(final_price, estimated_price, 0) * 0.3333, 2),
    runner_earnings = ROUND(COALESCE(final_price, estimated_price, 0) * 0.6667, 2),
    commission_rate = 33.33
WHERE status IN ('completed', 'confirmed')
  AND runner_id IS NOT NULL
  AND COALESCE(final_price, estimated_price, 0) > 0
  AND (company_commission IS NULL OR company_commission = 0);

-- ============================================================================
-- VERIFY THE UPDATES
-- ============================================================================

-- Check payments
SELECT 
    'Payments' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN company_commission IS NOT NULL AND company_commission > 0 THEN 1 END) as with_commission,
    SUM(amount) as total_amount,
    SUM(company_commission) as total_commission,
    SUM(runner_earnings) as total_earnings
FROM payments
WHERE runner_id IS NOT NULL;

-- Check transportation_bookings
SELECT 
    'Transportation Bookings' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN company_commission IS NOT NULL AND company_commission > 0 THEN 1 END) as with_commission,
    SUM(COALESCE(final_price, estimated_price, 0)) as total_amount,
    SUM(company_commission) as total_commission,
    SUM(runner_earnings) as total_earnings
FROM transportation_bookings
WHERE COALESCE(driver_id, runner_id) IS NOT NULL;

-- Check contract_bookings
SELECT 
    'Contract Bookings' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN company_commission IS NOT NULL AND company_commission > 0 THEN 1 END) as with_commission,
    SUM(COALESCE(final_price, estimated_price, 0)) as total_amount,
    SUM(company_commission) as total_commission,
    SUM(runner_earnings) as total_earnings
FROM contract_bookings
WHERE COALESCE(runner_id, driver_id) IS NOT NULL;

-- Check bus_service_bookings
SELECT 
    'Bus Service Bookings' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN company_commission IS NOT NULL AND company_commission > 0 THEN 1 END) as with_commission,
    SUM(COALESCE(final_price, estimated_price, 0)) as total_amount,
    SUM(company_commission) as total_commission,
    SUM(runner_earnings) as total_earnings
FROM bus_service_bookings
WHERE runner_id IS NOT NULL;

-- ============================================================================
-- CHECK RUNNER EARNINGS SUMMARY VIEW
-- ============================================================================
SELECT 
    runner_name,
    runner_email,
    total_bookings,
    completed_bookings,
    total_revenue,
    total_company_commission,
    total_runner_earnings
FROM runner_earnings_summary
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================================
-- DIAGNOSTIC: Check if bookings have runner assignments
-- ============================================================================

-- Check errands with runners
SELECT 
    'Errands' as type,
    COUNT(*) as total,
    COUNT(runner_id) as with_runner,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed
FROM errands;

-- Check transportation with runners
SELECT 
    'Transportation' as type,
    COUNT(*) as total,
    COUNT(driver_id) as with_driver,
    COUNT(CASE WHEN status IN ('completed', 'confirmed') THEN 1 END) as completed
FROM transportation_bookings;

-- Check contracts with runners
SELECT 
    'Contracts' as type,
    COUNT(*) as total,
    COUNT(COALESCE(runner_id, driver_id)) as with_runner,
    COUNT(CASE WHEN status IN ('completed', 'active', 'confirmed') THEN 1 END) as completed_or_active
FROM contract_bookings;

-- Check bus bookings with runners
SELECT 
    'Bus Services' as type,
    COUNT(*) as total,
    COUNT(runner_id) as with_runner,
    COUNT(CASE WHEN status IN ('completed', 'confirmed') THEN 1 END) as completed
FROM bus_service_bookings;

