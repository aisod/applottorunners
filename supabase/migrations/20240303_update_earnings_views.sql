-- Redefine Runner Earnings Summary to include all booking types
CREATE OR REPLACE VIEW runner_earnings_summary AS
WITH all_bookings AS (
    -- Errands
    SELECT 
        runner_id,
        amount,
        'errand' as type,
        payment_status
    FROM paytoday_transactions pt
    JOIN errands e ON pt.errand_id = e.id
    WHERE pt.status = 'completed'
    
    UNION ALL
    
    -- Transportation
    SELECT 
        driver_id as runner_id,
        amount,
        'transportation' as type,
        payment_status
    FROM paytoday_transactions pt
    JOIN transportation_bookings tb ON pt.errand_id = tb.id
    WHERE pt.status = 'completed'
    
    UNION ALL
    
    -- Contracts
    SELECT 
        driver_id as runner_id,
        amount,
        'contract' as type,
        payment_status
    FROM paytoday_transactions pt
    JOIN contract_bookings cb ON pt.errand_id = cb.id
    WHERE pt.status = 'completed'
    
    UNION ALL
    
    -- Bus Services
    SELECT 
        driver_id as runner_id,
        amount,
        'bus' as type,
        payment_status
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

-- Redefine Detailed Bookings Function
CREATE OR REPLACE FUNCTION get_runner_detailed_bookings(p_runner_id UUID)
RETURNS TABLE (
    id UUID,
    booking_type TEXT,
    description TEXT,
    customer_name TEXT,
    status TEXT,
    payment_status TEXT,
    amount DECIMAL,
    company_commission DECIMAL,
    runner_earnings DECIMAL,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    -- Errands
    SELECT 
        e.id,
        'errand'::TEXT as booking_type,
        e.title as description,
        u.full_name as customer_name,
        e.status::TEXT,
        e.payment_status::TEXT,
        pt.amount,
        (pt.amount * 0.333) as company_commission,
        (pt.amount * 0.667) as runner_earnings,
        e.created_at
    FROM paytoday_transactions pt
    JOIN errands e ON pt.errand_id = e.id
    JOIN users u ON e.customer_id = u.id
    WHERE e.runner_id = p_runner_id
    AND pt.status = 'completed'
    
    UNION ALL
    
    -- Transportation
    SELECT 
        tb.id,
        'transportation'::TEXT as booking_type,
        'Trip from ' || tb.pickup_location || ' to ' || tb.dropoff_location as description,
        u.full_name as customer_name,
        tb.status::TEXT,
        tb.payment_status::TEXT,
        pt.amount,
        (pt.amount * 0.333) as company_commission,
        (pt.amount * 0.667) as runner_earnings,
        tb.created_at
    FROM paytoday_transactions pt
    JOIN transportation_bookings tb ON pt.errand_id = tb.id
    JOIN users u ON tb.customer_id = u.id
    WHERE tb.driver_id = p_runner_id
    AND pt.status = 'completed'
    
    UNION ALL
    
    -- Contracts
    SELECT 
        cb.id,
        'contract'::TEXT as booking_type,
        'Contract for ' || cb.passenger_count || ' passengers' as description,
        u.full_name as customer_name,
        cb.status::TEXT,
        cb.payment_status::TEXT,
        pt.amount,
        (pt.amount * 0.333) as company_commission,
        (pt.amount * 0.667) as runner_earnings,
        cb.created_at
    FROM paytoday_transactions pt
    JOIN contract_bookings cb ON pt.errand_id = cb.id
    JOIN users u ON cb.customer_id = u.id
    WHERE cb.driver_id = p_runner_id
    AND pt.status = 'completed'
    
    UNION ALL
    
    -- Bus Services
    SELECT 
        bsb.id,
        'bus'::TEXT as booking_type,
        'Bus service from ' || bsb.pickup_location || ' to ' || bsb.dropoff_location as description,
        u.full_name as customer_name,
        bsb.status::TEXT,
        bsb.payment_status::TEXT,
        pt.amount,
        (pt.amount * 0.333) as company_commission,
        (pt.amount * 0.667) as runner_earnings,
        bsb.created_at
    FROM paytoday_transactions pt
    JOIN bus_service_bookings bsb ON pt.errand_id = bsb.id
    JOIN users u ON bsb.customer_id = u.id
    WHERE bsb.driver_id = p_runner_id
    AND pt.status = 'completed'
    
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;
