-- Fix Runner Earnings Summary View
-- The issue: The view was querying payments table for errands, but payments has no runner_id
-- Solution: Query errands table directly using e.runner_id
-- Note: Must specify all column types explicitly to avoid "column does not exist" errors

DROP VIEW IF EXISTS runner_earnings_summary CASCADE;

CREATE OR REPLACE VIEW runner_earnings_summary AS
SELECT 
    u.id AS runner_id,
    u.full_name AS runner_name,
    u.email AS runner_email,
    u.phone AS runner_phone,
    COALESCE(earnings_data.total_bookings, 0::bigint) AS total_bookings,
    COALESCE(earnings_data.completed_bookings, 0::bigint) AS completed_bookings,
    COALESCE(earnings_data.total_revenue, 0::numeric) AS total_revenue,
    COALESCE(earnings_data.total_company_commission, 0::numeric) AS total_company_commission,
    COALESCE(earnings_data.total_runner_earnings, 0::numeric) AS total_runner_earnings,
    COALESCE(earnings_data.errand_count, 0::bigint) AS errand_count,
    COALESCE(earnings_data.errand_revenue, 0::numeric) AS errand_revenue,
    COALESCE(earnings_data.errand_earnings, 0::numeric) AS errand_earnings,
    COALESCE(earnings_data.transportation_count, 0::bigint) AS transportation_count,
    COALESCE(earnings_data.transportation_revenue, 0::numeric) AS transportation_revenue,
    COALESCE(earnings_data.transportation_earnings, 0::numeric) AS transportation_earnings,
    COALESCE(earnings_data.contract_count, 0::bigint) AS contract_count,
    COALESCE(earnings_data.contract_revenue, 0::numeric) AS contract_revenue,
    COALESCE(earnings_data.contract_earnings, 0::numeric) AS contract_earnings,
    0 AS bus_count,
    0 AS bus_revenue,
    0 AS bus_earnings
FROM users u
LEFT JOIN (
    SELECT 
        runner_id,
        COUNT(*) AS total_bookings,
        SUM(CASE 
            WHEN booking_status IN ('completed', 'confirmed', 'active', 'in_progress', 'accepted') 
            THEN 1 ELSE 0 
        END) AS completed_bookings,
        SUM(booking_amount) AS total_revenue,
        SUM(company_commission) AS total_company_commission,
        SUM(runner_earnings) AS total_runner_earnings,
        -- Errand counts
        SUM(CASE WHEN booking_type = 'errand' THEN 1 ELSE 0 END) AS errand_count,
        SUM(CASE WHEN booking_type = 'errand' THEN booking_amount ELSE 0 END) AS errand_revenue,
        SUM(CASE WHEN booking_type = 'errand' THEN runner_earnings ELSE 0 END) AS errand_earnings,
        -- Transportation counts
        SUM(CASE WHEN booking_type = 'transportation' THEN 1 ELSE 0 END) AS transportation_count,
        SUM(CASE WHEN booking_type = 'transportation' THEN booking_amount ELSE 0 END) AS transportation_revenue,
        SUM(CASE WHEN booking_type = 'transportation' THEN runner_earnings ELSE 0 END) AS transportation_earnings,
        -- Contract counts
        SUM(CASE WHEN booking_type = 'contract' THEN 1 ELSE 0 END) AS contract_count,
        SUM(CASE WHEN booking_type = 'contract' THEN booking_amount ELSE 0 END) AS contract_revenue,
        SUM(CASE WHEN booking_type = 'contract' THEN runner_earnings ELSE 0 END) AS contract_earnings
    FROM (
        -- ERRANDS: Query errands table directly, not payments!
        SELECT 
            e.runner_id,
            'errand' AS booking_type,
            e.status AS booking_status,
            e.price_amount AS booking_amount,
            ROUND(COALESCE(p.company_commission, e.price_amount * 0.3333), 2) AS company_commission,
            ROUND(COALESCE(p.runner_earnings, e.price_amount * 0.6667), 2) AS runner_earnings
        FROM errands e
        LEFT JOIN payments p ON e.id = p.errand_id
        WHERE e.runner_id IS NOT NULL
        
        UNION ALL
        
        -- TRANSPORTATION BOOKINGS
        SELECT 
            COALESCE(tb.driver_id, tb.runner_id) AS runner_id,
            'transportation' AS booking_type,
            tb.status AS booking_status,
            COALESCE(tb.final_price, tb.estimated_price, 0) AS booking_amount,
            ROUND(COALESCE(tb.company_commission, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.3333), 2) AS company_commission,
            ROUND(COALESCE(tb.runner_earnings, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.6667), 2) AS runner_earnings
        FROM transportation_bookings tb
        WHERE COALESCE(tb.driver_id, tb.runner_id) IS NOT NULL
        
        UNION ALL
        
        -- CONTRACT BOOKINGS
        SELECT 
            COALESCE(cb.runner_id, cb.driver_id) AS runner_id,
            'contract' AS booking_type,
            cb.status AS booking_status,
            COALESCE(cb.final_price, cb.estimated_price, 0) AS booking_amount,
            ROUND(COALESCE(cb.company_commission, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.3333), 2) AS company_commission,
            ROUND(COALESCE(cb.runner_earnings, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.6667), 2) AS runner_earnings
        FROM contract_bookings cb
        WHERE COALESCE(cb.runner_id, cb.driver_id) IS NOT NULL
    ) all_bookings
    GROUP BY runner_id
) earnings_data ON u.id = earnings_data.runner_id
WHERE earnings_data.runner_id IS NOT NULL OR u.user_type = 'runner' OR u.is_verified = true;

COMMENT ON VIEW runner_earnings_summary IS 'Summary view of runner earnings - FIXED to query errands table directly instead of payments table';

-- Grant permissions
GRANT SELECT ON runner_earnings_summary TO authenticated;

