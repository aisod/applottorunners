-- Exclude shopping budget from runner earnings and company commission
-- So the platform profit and runner earnings are only on the service fee for shopping errands.

-- 1. runner_earnings_summary: for errands, use (amount - shopping_budget) as commissionable amount
DROP VIEW IF EXISTS runner_earnings_summary CASCADE;

CREATE VIEW runner_earnings_summary AS
WITH errand_totals AS (
    -- Per-errand total paid and commissionable amount (total - shopping_budget)
    SELECT 
        e.runner_id,
        (COALESCE(SUM(pt.amount), 0) - COALESCE((e.pricing_modifiers->>'shopping_budget')::numeric, 0))::decimal AS amount,
        'errand'::text AS type
    FROM paytoday_transactions pt
    JOIN errands e ON pt.errand_id = e.id
    WHERE pt.status = 'completed'
    AND e.runner_id IS NOT NULL
    GROUP BY e.id, e.runner_id, e.pricing_modifiers

    UNION ALL

    -- Errands fallback: from payments table (legacy), one row per errand
    SELECT 
        e.runner_id,
        (COALESCE(SUM(p.amount), 0) - COALESCE((e.pricing_modifiers->>'shopping_budget')::numeric, 0))::decimal AS amount,
        'errand'::text AS type
    FROM payments p
    JOIN errands e ON p.errand_id = e.id
    WHERE p.status = 'completed'
    AND e.runner_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM paytoday_transactions pt2
        WHERE pt2.errand_id = p.errand_id AND pt2.status = 'completed'
    )
    GROUP BY e.id, e.runner_id, e.pricing_modifiers
),
all_bookings AS (
    SELECT * FROM errand_totals

    UNION ALL

    -- Transportation
    SELECT 
        tb.driver_id AS runner_id,
        COALESCE(tb.final_price, tb.estimated_price, 0)::decimal AS amount,
        'transportation'::text AS type
    FROM transportation_bookings tb
    WHERE tb.driver_id IS NOT NULL
    AND tb.status IN ('completed', 'confirmed', 'active', 'in_progress')
    AND COALESCE(tb.final_price, tb.estimated_price, 0) > 0

    UNION ALL

    -- Contracts
    SELECT 
        COALESCE(cb.runner_id, cb.driver_id) AS runner_id,
        COALESCE(cb.final_price, cb.estimated_price, 0)::decimal AS amount,
        'contract'::text AS type
    FROM contract_bookings cb
    WHERE (cb.runner_id IS NOT NULL OR cb.driver_id IS NOT NULL)
    AND cb.status IN ('completed', 'confirmed', 'active', 'in_progress')
    AND COALESCE(cb.final_price, cb.estimated_price, 0) > 0

    UNION ALL

    -- Bus
    SELECT 
        bsb.runner_id,
        COALESCE(bsb.final_price, bsb.estimated_price, 0)::decimal AS amount,
        'bus'::text AS type
    FROM bus_service_bookings bsb
    WHERE bsb.runner_id IS NOT NULL
    AND bsb.status IN ('completed', 'confirmed')
    AND COALESCE(bsb.final_price, bsb.estimated_price, 0) > 0
)
SELECT 
    u.id AS runner_id,
    u.full_name AS runner_name,
    u.email AS runner_email,
    COUNT(b.runner_id)::int AS total_bookings,
    COALESCE(SUM(b.amount), 0) AS total_revenue,
    COALESCE(SUM(b.amount * 0.333), 0) AS total_company_commission,
    COALESCE(SUM(b.amount * 0.667), 0) AS total_runner_earnings,
    COUNT(CASE WHEN b.type = 'errand' THEN 1 END)::int AS errand_count,
    COUNT(CASE WHEN b.type = 'transportation' THEN 1 END)::int AS transportation_count,
    COUNT(CASE WHEN b.type = 'contract' THEN 1 END)::int AS contract_count,
    COUNT(CASE WHEN b.type = 'bus' THEN 1 END)::int AS bus_count
FROM users u
LEFT JOIN all_bookings b ON u.id = b.runner_id
WHERE u.user_type = 'runner'
   OR u.id IN (SELECT runner_id FROM all_bookings)
GROUP BY u.id, u.full_name, u.email;

GRANT SELECT ON runner_earnings_summary TO authenticated;
GRANT SELECT ON runner_earnings_summary TO service_role;

COMMENT ON VIEW runner_earnings_summary IS 'Runner earnings: for shopping errands, revenue/commission use (amount - shopping_budget) so platform profit excludes customer shopping funds';

-- 2. get_runner_detailed_bookings: for errands return shopping_budget and base commission on service amount only
DROP FUNCTION IF EXISTS get_runner_detailed_bookings(uuid);

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
    description TEXT,
    shopping_budget DECIMAL(10,2),
    service_type TEXT,
    pricing_modifiers JSONB
) AS $$
BEGIN
    RETURN QUERY
    -- Errands: commission/earnings on (price_amount - shopping_budget); return full amount and shopping_budget for display
    SELECT 
        e.id AS booking_id,
        'Errand'::TEXT AS booking_type,
        e.id::TEXT AS booking_reference,
        u.full_name AS customer_name,
        e.created_at AS booking_date,
        e.status,
        e.price_amount AS amount,
        ROUND((e.price_amount - COALESCE((e.pricing_modifiers->>'shopping_budget')::numeric, 0)) * 0.3333, 2)::decimal AS company_commission,
        ROUND((e.price_amount - COALESCE((e.pricing_modifiers->>'shopping_budget')::numeric, 0)) * 0.6667, 2)::decimal AS runner_earnings,
        e.title AS description,
        COALESCE((e.pricing_modifiers->>'shopping_budget')::numeric, 0)::decimal AS shopping_budget,
        (e.pricing_modifiers->>'service_type')::TEXT AS service_type,
        e.pricing_modifiers AS pricing_modifiers
    FROM errands e
    JOIN users u ON e.customer_id = u.id
    WHERE e.runner_id = p_runner_id

    UNION ALL

    -- Transportation: no shopping_budget
    SELECT 
        tb.id AS booking_id,
        'Transportation'::TEXT AS booking_type,
        tb.id::TEXT AS booking_reference,
        u.full_name AS customer_name,
        tb.created_at AS booking_date,
        tb.status,
        COALESCE(tb.final_price, tb.estimated_price, 0)::decimal AS amount,
        ROUND(COALESCE(tb.company_commission, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.3333), 2)::decimal AS company_commission,
        ROUND(COALESCE(tb.runner_earnings, COALESCE(tb.final_price, tb.estimated_price, 0) * 0.6667), 2)::decimal AS runner_earnings,
        CONCAT(COALESCE(tb.pickup_location, 'N/A'), ' → ', COALESCE(tb.dropoff_location, 'N/A'))::TEXT AS description,
        0::decimal AS shopping_budget,
        NULL::TEXT AS service_type,
        NULL::jsonb AS pricing_modifiers
    FROM transportation_bookings tb
    JOIN users u ON tb.user_id = u.id
    WHERE COALESCE(tb.runner_id, tb.driver_id) = p_runner_id

    UNION ALL

    -- Contract bookings
    SELECT 
        cb.id AS booking_id,
        'Contract'::TEXT AS booking_type,
        COALESCE(cb.contract_reference, cb.id::TEXT) AS booking_reference,
        u.full_name AS customer_name,
        cb.created_at AS booking_date,
        cb.status,
        COALESCE(cb.final_price, cb.estimated_price, 0)::decimal AS amount,
        ROUND(COALESCE(cb.company_commission, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.3333), 2)::decimal AS company_commission,
        ROUND(COALESCE(cb.runner_earnings, COALESCE(cb.final_price, cb.estimated_price, 0) * 0.6667), 2)::decimal AS runner_earnings,
        COALESCE(cb.description, CONCAT(COALESCE(cb.pickup_location, 'N/A'), ' → ', COALESCE(cb.dropoff_location, 'N/A')))::TEXT AS description,
        0::decimal AS shopping_budget,
        NULL::TEXT AS service_type,
        NULL::jsonb AS pricing_modifiers
    FROM contract_bookings cb
    JOIN users u ON cb.user_id = u.id
    WHERE COALESCE(cb.runner_id, cb.driver_id) = p_runner_id

    ORDER BY booking_date DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_runner_detailed_bookings IS 'Detailed bookings for runner: for shopping errands, commission/earnings on service only; returns shopping_budget and pricing_modifiers for display';
