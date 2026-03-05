-- Ensure PayToday payments flow to Provider Accounting
-- 1. Fix runner_earnings_summary to use errand's runner_id so payments are always attributed
-- 2. Grant admin SELECT on views used by Payment Tracking and Accounting

-- Fix: Use e.runner_id for errands so completed payments count in accounting even if pt.runner_id is null
CREATE OR REPLACE VIEW runner_earnings_summary AS
WITH all_bookings AS (
    -- Errands: use errand's runner_id so payments go to accounting for the assigned runner
    SELECT 
        e.runner_id,
        pt.amount,
        'errand'::text as type,
        e.payment_status::text as payment_status
    FROM paytoday_transactions pt
    JOIN errands e ON pt.errand_id = e.id
    WHERE pt.status = 'completed'
    
    UNION ALL
    
    -- Transportation
    SELECT 
        tb.driver_id as runner_id,
        pt.amount,
        'transportation'::text as type,
        (tb.payment_status::text) as payment_status
    FROM paytoday_transactions pt
    JOIN transportation_bookings tb ON pt.errand_id = tb.id
    WHERE pt.status = 'completed'
    
    UNION ALL
    
    -- Contracts
    SELECT 
        cb.driver_id as runner_id,
        pt.amount,
        'contract'::text as type,
        (cb.payment_status::text) as payment_status
    FROM paytoday_transactions pt
    JOIN contract_bookings cb ON pt.errand_id = cb.id
    WHERE pt.status = 'completed'
    
    UNION ALL
    
    -- Bus Services
    SELECT 
        bsb.driver_id as runner_id,
        pt.amount,
        'bus'::text as type,
        (bsb.payment_status::text) as payment_status
    FROM paytoday_transactions pt
    JOIN bus_service_bookings bsb ON pt.errand_id = bsb.id
    WHERE pt.status = 'completed'
)
SELECT 
    u.id as runner_id,
    u.full_name as runner_name,
    u.email as runner_email,
    COUNT(b.runner_id) as total_bookings,
    COALESCE(SUM(b.amount), 0) as total_revenue,
    COALESCE(SUM(b.amount * 0.333), 0) as total_company_commission,
    COALESCE(SUM(b.amount * 0.667), 0) as total_runner_earnings,
    COUNT(CASE WHEN b.type = 'errand' THEN 1 END) as errand_count,
    COUNT(CASE WHEN b.type = 'transportation' THEN 1 END) as transportation_count,
    COUNT(CASE WHEN b.type = 'contract' THEN 1 END) as contract_count,
    COUNT(CASE WHEN b.type = 'bus' THEN 1 END) as bus_count
FROM users u
LEFT JOIN all_bookings b ON u.id = b.runner_id
WHERE u.user_type = 'runner'
GROUP BY u.id, u.full_name, u.email;
