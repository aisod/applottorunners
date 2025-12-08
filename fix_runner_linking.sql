-- ============================================================================
-- FIX RUNNER LINKING IN PROVIDER ACCOUNTING
-- This script fixes the issue where bookings are not linked to runners
-- ============================================================================

-- ============================================================================
-- STEP 1: Create improved runner_earnings_summary view
-- This version handles bookings that link through services -> providers
-- ============================================================================

DROP VIEW IF EXISTS runner_earnings_summary CASCADE;

CREATE OR REPLACE VIEW runner_earnings_summary AS
SELECT 
    u.id AS runner_id,
    u.full_name AS runner_name,
    u.email AS runner_email,
    u.phone AS runner_phone,
    COALESCE(earnings_data.total_bookings, 0) AS total_bookings,
    COALESCE(earnings_data.completed_bookings, 0) AS completed_bookings,
    COALESCE(earnings_data.total_revenue, 0) AS total_revenue,
    COALESCE(earnings_data.total_company_commission, 0) AS total_company_commission,
    COALESCE(earnings_data.total_runner_earnings, 0) AS total_runner_earnings,
    COALESCE(earnings_data.errand_count, 0) AS errand_count,
    COALESCE(earnings_data.errand_revenue, 0) AS errand_revenue,
    COALESCE(earnings_data.errand_earnings, 0) AS errand_earnings,
    COALESCE(earnings_data.transportation_count, 0) AS transportation_count,
    COALESCE(earnings_data.transportation_revenue, 0) AS transportation_revenue,
    COALESCE(earnings_data.transportation_earnings, 0) AS transportation_earnings,
    COALESCE(earnings_data.contract_count, 0) AS contract_count,
    COALESCE(earnings_data.contract_revenue, 0) AS contract_revenue,
    COALESCE(earnings_data.contract_earnings, 0) AS contract_earnings,
    0 AS bus_count,
    0 AS bus_revenue,
    0 AS bus_earnings
FROM users u
LEFT JOIN (
    SELECT 
        runner_id,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN booking_status IN ('completed', 'confirmed', 'active', 'in_progress', 'accepted') THEN 1 ELSE 0 END) AS completed_bookings,
        SUM(booking_amount) AS total_revenue,
        SUM(company_commission) AS total_company_commission,
        SUM(runner_earnings) AS total_runner_earnings,
        SUM(CASE WHEN booking_type = 'errand' THEN 1 ELSE 0 END) AS errand_count,
        SUM(CASE WHEN booking_type = 'errand' THEN booking_amount ELSE 0 END) AS errand_revenue,
        SUM(CASE WHEN booking_type = 'errand' THEN runner_earnings ELSE 0 END) AS errand_earnings,
        SUM(CASE WHEN booking_type = 'transportation' THEN 1 ELSE 0 END) AS transportation_count,
        SUM(CASE WHEN booking_type = 'transportation' THEN booking_amount ELSE 0 END) AS transportation_revenue,
        SUM(CASE WHEN booking_type = 'transportation' THEN runner_earnings ELSE 0 END) AS transportation_earnings,
        SUM(CASE WHEN booking_type = 'contract' THEN 1 ELSE 0 END) AS contract_count,
        SUM(CASE WHEN booking_type = 'contract' THEN booking_amount ELSE 0 END) AS contract_revenue,
        SUM(CASE WHEN booking_type = 'contract' THEN runner_earnings ELSE 0 END) AS contract_earnings
    FROM (
        -- Errands via payments
        SELECT 
            p.runner_id,
            'errand' AS booking_type,
            p.status AS booking_status,
            p.amount AS booking_amount,
            COALESCE(p.company_commission, p.amount * 0.3333) AS company_commission,
            COALESCE(p.runner_earnings, p.amount * 0.6667) AS runner_earnings
        FROM payments p
        WHERE p.runner_id IS NOT NULL
        
        UNION ALL
        
        -- Transportation bookings - Use driver_id or runner_id (direct assignment)
        SELECT 
            COALESCE(tb.driver_id, tb.runner_id) AS runner_id,
            'transportation' AS booking_type,
            tb.status AS booking_status,
            COALESCE(tb.final_price, tb.estimated_price, 0) AS booking_amount,
            COALESCE(tb.company_commission, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.3333) AS company_commission,
            COALESCE(tb.runner_earnings, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.6667) AS runner_earnings
        FROM transportation_bookings tb
        WHERE COALESCE(tb.driver_id, tb.runner_id) IS NOT NULL
        
        UNION ALL
        
        -- Contract bookings
        SELECT 
            COALESCE(cb.runner_id, cb.driver_id) AS runner_id,
            'contract' AS booking_type,
            cb.status AS booking_status,
            COALESCE(cb.final_price, cb.estimated_price, 0) AS booking_amount,
            COALESCE(cb.company_commission, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.3333) AS company_commission,
            COALESCE(cb.runner_earnings, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.6667) AS runner_earnings
        FROM contract_bookings cb
        WHERE COALESCE(cb.runner_id, cb.driver_id) IS NOT NULL
        
        -- Note: Bus service bookings are excluded from provider accounting
    ) all_bookings
    GROUP BY runner_id
) earnings_data ON u.id = earnings_data.runner_id
WHERE earnings_data.runner_id IS NOT NULL OR u.user_type = 'runner' OR u.is_verified = true;

-- Grant permissions
GRANT SELECT ON runner_earnings_summary TO authenticated;

-- ============================================================================
-- STEP 2: Create helper function to get runner detailed bookings
-- ============================================================================

CREATE OR REPLACE FUNCTION get_runner_detailed_bookings(p_runner_id UUID)
RETURNS TABLE(
    booking_id UUID,
    booking_type TEXT,
    booking_reference TEXT,
    customer_name TEXT,
    booking_date TIMESTAMP WITH TIME ZONE,
    status TEXT,
    amount DECIMAL(10,2),
    company_commission DECIMAL(10,2),
    runner_earnings DECIMAL(10,2),
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Errands
    SELECT 
        e.id AS booking_id,
        'Errand'::TEXT AS booking_type,
        e.id::TEXT AS booking_reference,
        u.full_name AS customer_name,
        e.created_at AS booking_date,
        e.status,
        e.price_amount AS amount,
        ROUND(COALESCE(p.company_commission, e.price_amount * 0.3333), 2) AS company_commission,
        ROUND(COALESCE(p.runner_earnings, e.price_amount * 0.6667), 2) AS runner_earnings,
        e.title AS description
    FROM errands e
    JOIN users u ON e.customer_id = u.id
    LEFT JOIN payments p ON e.id = p.errand_id
    WHERE e.runner_id = p_runner_id
    
    UNION ALL
    
    -- Transportation bookings
    SELECT 
        tb.id AS booking_id,
        'Transportation'::TEXT AS booking_type,
        tb.booking_reference AS booking_reference,
        u.full_name AS customer_name,
        tb.created_at AS booking_date,
        tb.status,
        COALESCE(tb.final_price, tb.estimated_price) AS amount,
        ROUND(COALESCE(tb.company_commission, COALESCE(tb.final_price, tb.estimated_price) * 0.3333), 2) AS company_commission,
        ROUND(COALESCE(tb.runner_earnings, COALESCE(tb.final_price, tb.estimated_price) * 0.6667), 2) AS runner_earnings,
        CONCAT(tb.pickup_location, ' → ', tb.dropoff_location) AS description
    FROM transportation_bookings tb
    JOIN users u ON tb.user_id = u.id
    WHERE COALESCE(tb.driver_id, tb.runner_id) = p_runner_id
    
    UNION ALL
    
    -- Contract bookings
    SELECT 
        cb.id AS booking_id,
        'Contract'::TEXT AS booking_type,
        cb.booking_reference AS booking_reference,
        u.full_name AS customer_name,
        cb.created_at AS booking_date,
        cb.status,
        COALESCE(cb.final_price, cb.estimated_price) AS amount,
        ROUND(COALESCE(cb.company_commission, COALESCE(cb.final_price, cb.estimated_price) * 0.3333), 2) AS company_commission,
        ROUND(COALESCE(cb.runner_earnings, COALESCE(cb.final_price, cb.estimated_price) * 0.6667), 2) AS runner_earnings,
        CONCAT(cb.pickup_location, ' → ', cb.dropoff_location) AS description
    FROM contract_bookings cb
    JOIN users u ON cb.user_id = u.id
    WHERE COALESCE(cb.runner_id, cb.driver_id) = p_runner_id
    
    -- Note: Bus service bookings are excluded from provider accounting
    
    ORDER BY booking_date DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON VIEW runner_earnings_summary IS 'Summary view of runner earnings (excludes bus service bookings) - uses direct driver_id/runner_id assignment';
COMMENT ON FUNCTION get_runner_detailed_bookings IS 'Returns detailed booking list for a specific runner with commission breakdown (excludes bus service bookings)';

-- ============================================================================
-- STEP 3: Test the updated view
-- ============================================================================

SELECT 
    '=== Testing Updated View ===' as test_section,
    COUNT(*) as total_runners,
    SUM(total_bookings) as total_bookings,
    SUM(total_revenue) as total_revenue,
    SUM(total_company_commission) as total_commission,
    SUM(total_runner_earnings) as total_runner_earnings
FROM runner_earnings_summary;

-- Show sample data
SELECT 
    runner_name,
    total_bookings,
    total_revenue,
    transportation_count,
    bus_count,
    errand_count,
    contract_count
FROM runner_earnings_summary 
WHERE total_bookings > 0
ORDER BY total_revenue DESC 
LIMIT 10;

-- Show runners without bookings (should be minimal now)
SELECT 
    runner_name,
    runner_email,
    total_bookings
FROM runner_earnings_summary 
WHERE total_bookings = 0
LIMIT 5;

