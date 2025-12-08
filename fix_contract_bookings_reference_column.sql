-- Fix the get_runner_detailed_bookings function to use correct column name
-- The contract_bookings table has 'contract_reference', not 'booking_reference'

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
        tb.id::TEXT AS booking_reference,
        u.full_name AS customer_name,
        tb.created_at AS booking_date,
        tb.status,
        COALESCE(tb.final_price, tb.estimated_price) AS amount,
        ROUND(COALESCE(tb.company_commission, COALESCE(tb.final_price, tb.estimated_price) * 0.3333), 2) AS company_commission,
        ROUND(COALESCE(tb.runner_earnings, COALESCE(tb.final_price, tb.estimated_price) * 0.6667), 2) AS runner_earnings,
        CONCAT(COALESCE(tb.pickup_location, 'N/A'), ' → ', COALESCE(tb.dropoff_location, 'N/A')) AS description
    FROM transportation_bookings tb
    JOIN users u ON tb.user_id = u.id
    WHERE COALESCE(tb.runner_id, tb.driver_id) = p_runner_id
    
    UNION ALL
    
    -- Contract bookings (FIXED: using contract_reference instead of booking_reference)
    SELECT 
        cb.id AS booking_id,
        'Contract'::TEXT AS booking_type,
        COALESCE(cb.contract_reference, cb.id::TEXT) AS booking_reference,
        u.full_name AS customer_name,
        cb.created_at AS booking_date,
        cb.status,
        COALESCE(cb.final_price, cb.estimated_price) AS amount,
        ROUND(COALESCE(cb.company_commission, COALESCE(cb.final_price, cb.estimated_price) * 0.3333), 2) AS company_commission,
        ROUND(COALESCE(cb.runner_earnings, COALESCE(cb.final_price, cb.estimated_price) * 0.6667), 2) AS runner_earnings,
        CONCAT(COALESCE(cb.pickup_location, 'N/A'), ' → ', COALESCE(cb.dropoff_location, 'N/A')) AS description
    FROM contract_bookings cb
    JOIN users u ON cb.user_id = u.id
    WHERE COALESCE(cb.runner_id, cb.driver_id) = p_runner_id
    
    -- Note: Bus service bookings are excluded from runner accounting
    
    ORDER BY booking_date DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_runner_detailed_bookings IS 'Returns detailed booking list for a specific runner with commission breakdown (EXCLUDES bus service bookings) - FIXED to use correct column names';

