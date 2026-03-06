-- Fix runner_earnings_summary to show accounting data
-- DROP first to avoid "cannot change name of view column" when column order differs
DROP VIEW IF EXISTS runner_earnings_summary CASCADE;

-- Problem: View only used paytoday_transactions, but:
--   1. paytoday_transactions.errand_id REFERENCES errands(id) - so transportation/bus/contract
--      payments can't be stored there (different table IDs)
--   2. If no completed paytoday_transactions exist, all values were 0
-- Solution: Pull from SOURCE tables (transportation_bookings, etc.) directly for their
--   amounts, and from paytoday_transactions only for errands (where errand_id matches)

CREATE VIEW runner_earnings_summary AS
WITH all_bookings AS (
    -- 1. Errands: from paytoday_transactions (only source that has errand payments)
    SELECT 
        e.runner_id,
        pt.amount,
        'errand'::text as type
    FROM paytoday_transactions pt
    JOIN errands e ON pt.errand_id = e.id
    WHERE pt.status = 'completed'
    AND e.runner_id IS NOT NULL

    UNION ALL

    -- 2. Errands fallback: from payments table (legacy)
    SELECT 
        e.runner_id,
        p.amount,
        'errand'::text as type
    FROM payments p
    JOIN errands e ON p.errand_id = e.id
    WHERE p.status = 'completed'
    AND e.runner_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM paytoday_transactions pt2
        WHERE pt2.errand_id = p.errand_id AND pt2.status = 'completed'
    )

    UNION ALL

    -- 3. Transportation: from transportation_bookings (pt.errand_id can't reference tb.id)
    SELECT 
        tb.driver_id as runner_id,
        COALESCE(tb.final_price, tb.estimated_price, 0)::decimal as amount,
        'transportation'::text as type
    FROM transportation_bookings tb
    WHERE tb.driver_id IS NOT NULL
    AND tb.status IN ('completed', 'confirmed', 'active', 'in_progress')
    AND COALESCE(tb.final_price, tb.estimated_price, 0) > 0

    UNION ALL

    -- 4. Contracts: from contract_bookings
    SELECT 
        COALESCE(cb.runner_id, cb.driver_id) as runner_id,
        COALESCE(cb.final_price, cb.estimated_price, 0)::decimal as amount,
        'contract'::text as type
    FROM contract_bookings cb
    WHERE (cb.runner_id IS NOT NULL OR cb.driver_id IS NOT NULL)
    AND cb.status IN ('completed', 'confirmed', 'active', 'in_progress')
    AND COALESCE(cb.final_price, cb.estimated_price, 0) > 0

    UNION ALL

    -- 5. Bus: from bus_service_bookings (runner_id is the provider)
    SELECT 
        bsb.runner_id,
        COALESCE(bsb.final_price, bsb.estimated_price, 0)::decimal as amount,
        'bus'::text as type
    FROM bus_service_bookings bsb
    WHERE bsb.runner_id IS NOT NULL
    AND bsb.status IN ('completed', 'confirmed')
    AND COALESCE(bsb.final_price, bsb.estimated_price, 0) > 0
)
SELECT 
    u.id as runner_id,
    u.full_name as runner_name,
    u.email as runner_email,
    COUNT(b.runner_id)::int as total_bookings,
    COALESCE(SUM(b.amount), 0) as total_revenue,
    COALESCE(SUM(b.amount * 0.333), 0) as total_company_commission,
    COALESCE(SUM(b.amount * 0.667), 0) as total_runner_earnings,
    COUNT(CASE WHEN b.type = 'errand' THEN 1 END)::int as errand_count,
    COUNT(CASE WHEN b.type = 'transportation' THEN 1 END)::int as transportation_count,
    COUNT(CASE WHEN b.type = 'contract' THEN 1 END)::int as contract_count,
    COUNT(CASE WHEN b.type = 'bus' THEN 1 END)::int as bus_count
FROM users u
LEFT JOIN all_bookings b ON u.id = b.runner_id
WHERE u.user_type = 'runner'
   OR u.id IN (SELECT runner_id FROM all_bookings)
GROUP BY u.id, u.full_name, u.email;

GRANT SELECT ON runner_earnings_summary TO authenticated;
GRANT SELECT ON runner_earnings_summary TO service_role;
