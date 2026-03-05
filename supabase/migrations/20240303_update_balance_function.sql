-- Update get_runner_withdrawable_balance to include all booking types
-- (Total released earnings - total processed withdrawals)

CREATE OR REPLACE FUNCTION get_runner_withdrawable_balance(p_runner_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    total_released DECIMAL;
    total_withdrawn DECIMAL;
    errand_released DECIMAL;
    transport_released DECIMAL;
    contract_released DECIMAL;
    bus_released DECIMAL;
BEGIN
    -- 1. Count released errands
    SELECT COALESCE(SUM(amount * 0.667), 0)
    INTO errand_released
    FROM paytoday_transactions pt
    JOIN errands e ON pt.errand_id = e.id
    WHERE e.runner_id = p_runner_id
    AND pt.status = 'completed'
    AND e.payment_status = 'released_to_runner';

    -- 2. Count released transportation bookings
    SELECT COALESCE(SUM(amount * 0.667), 0)
    INTO transport_released
    FROM paytoday_transactions pt
    JOIN transportation_bookings tb ON pt.errand_id = tb.id
    WHERE tb.driver_id = p_runner_id
    AND pt.status = 'completed'
    AND tb.payment_status = 'released_to_runner';

    -- 3. Count released contract bookings
    SELECT COALESCE(SUM(amount * 0.667), 0)
    INTO contract_released
    FROM paytoday_transactions pt
    JOIN contract_bookings cb ON pt.errand_id = cb.id
    WHERE cb.driver_id = p_runner_id
    AND pt.status = 'completed'
    AND cb.payment_status = 'released_to_runner';

    -- 4. Count released bus service bookings
    SELECT COALESCE(SUM(amount * 0.667), 0)
    INTO bus_released
    FROM paytoday_transactions pt
    JOIN bus_service_bookings bsb ON pt.errand_id = bsb.id
    WHERE bsb.driver_id = p_runner_id -- Assuming bus driver gets earnings; might be bus owner
    AND pt.status = 'completed'
    AND bsb.payment_status = 'released_to_runner';

    total_released := errand_released + transport_released + contract_released + bus_released;

    -- 5. Count processed withdrawals
    SELECT COALESCE(SUM(amount), 0)
    INTO total_withdrawn
    FROM withdrawal_requests
    WHERE runner_id = p_runner_id
    AND status IN ('approved', 'completed');
    
    RETURN GREATEST(total_released - total_withdrawn, 0);
END;
$$ LANGUAGE plpgsql;
