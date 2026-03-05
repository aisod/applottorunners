-- Create a unified view for all transactions for Admin visibility
CREATE OR REPLACE VIEW admin_all_transactions AS
SELECT 
    pt.transaction_id as external_id,
    pt.errand_id as booking_id,
    pt.amount,
    pt.status,
    pt.payment_type,
    pt.created_at,
    pt.completed_at,
    c.full_name as customer_name,
    c.email as customer_email,
    r.full_name as runner_name,
    r.email as runner_email,
    -- Determine booking type and title logic
    CASE 
        WHEN e.id IS NOT NULL THEN 'errand'
        WHEN tb.id IS NOT NULL THEN 'transportation'
        WHEN cb.id IS NOT NULL THEN 'contract'
        WHEN bsb.id IS NOT NULL THEN 'bus'
        ELSE 'unknown'
    END as booking_type,
    CASE
        WHEN e.id IS NOT NULL THEN e.title
        WHEN tb.id IS NOT NULL THEN 'Trip: ' || tb.pickup_location || ' to ' || tb.dropoff_location
        WHEN cb.id IS NOT NULL THEN 'Contract: ' || cb.id::text
        WHEN bsb.id IS NOT NULL THEN 'Bus: ' || bsb.pickup_location || ' to ' || bsb.dropoff_location
        ELSE 'Payment for ' || pt.errand_id::text
    END as title
FROM paytoday_transactions pt
LEFT JOIN users c ON pt.customer_id = c.id
LEFT JOIN users r ON pt.runner_id = r.id
LEFT JOIN errands e ON pt.errand_id = e.id
LEFT JOIN transportation_bookings tb ON pt.errand_id = tb.id
LEFT JOIN contract_bookings cb ON pt.errand_id = cb.id
LEFT JOIN bus_service_bookings bsb ON pt.errand_id = bsb.id;
