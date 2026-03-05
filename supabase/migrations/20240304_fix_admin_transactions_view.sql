-- Fix Admin Transactions View to use source tables instead of paytoday_transactions
-- This ensures all bookings show up in Payment Tracking even if they aren't in the transaction log

DROP VIEW IF EXISTS admin_all_transactions;
CREATE VIEW admin_all_transactions AS
SELECT 
    -- ERRANDS (from payments table)
    p.id::text as external_id,
    p.errand_id as booking_id,
    p.amount,
    p.status,
    'paytoday' as payment_type,
    p.created_at,
    p.completed_at as completed_at, -- Changed from updated_at to completed_at
    c.full_name as customer_name,
    c.email as customer_email,
    r.full_name as runner_name,
    r.email as runner_email,
    'errand' as booking_type,
    e.title as title
FROM payments p
JOIN errands e ON p.errand_id = e.id
LEFT JOIN users c ON e.customer_id = c.id
LEFT JOIN users r ON COALESCE(p.runner_id, e.runner_id) = r.id

UNION ALL

SELECT 
    -- TRANSPORTATION
    tb.id::text as external_id,
    tb.id as booking_id,
    COALESCE(tb.final_price, tb.estimated_price, 0) as amount,
    tb.status,
    'paytoday' as payment_type,
    tb.created_at,
    tb.updated_at as completed_at,
    c.full_name as customer_name,
    c.email as customer_email,
    r.full_name as runner_name,
    r.email as runner_email,
    'transportation' as booking_type,
    'Trip: ' || tb.pickup_location || ' to ' || tb.dropoff_location as title
FROM transportation_bookings tb
LEFT JOIN users c ON tb.user_id = c.id
LEFT JOIN users r ON COALESCE(tb.driver_id, tb.runner_id) = r.id
WHERE tb.status IN ('completed', 'confirmed', 'active', 'in_progress')

UNION ALL

SELECT 
    -- CONTRACTS
    cb.id::text as external_id,
    cb.id as booking_id,
    COALESCE(cb.final_price, cb.estimated_price, 0) as amount,
    cb.status,
    'paytoday' as payment_type,
    cb.created_at,
    cb.updated_at as completed_at,
    c.full_name as customer_name,
    c.email as customer_email,
    r.full_name as runner_name,
    r.email as runner_email,
    'contract' as booking_type,
    'Contract: ' || cb.pickup_location || ' to ' || cb.dropoff_location as title
FROM contract_bookings cb
LEFT JOIN users c ON cb.user_id = c.id
LEFT JOIN users r ON COALESCE(cb.runner_id, cb.driver_id) = r.id
WHERE cb.status IN ('completed', 'confirmed', 'active')

UNION ALL

SELECT 
    -- BUS
    bsb.id::text as external_id,
    bsb.id as booking_id,
    COALESCE(bsb.final_price, bsb.estimated_price, 0) as amount,
    bsb.status,
    'paytoday' as payment_type,
    bsb.created_at,
    bsb.updated_at as completed_at,
    c.full_name as customer_name,
    c.email as customer_email,
    r.full_name as runner_name,
    r.email as runner_email,
    'bus' as booking_type,
    'Bus: ' || bsb.origin_region || ' to ' || bsb.destination_region as title
FROM bus_service_bookings bsb
LEFT JOIN users c ON bsb.user_id = c.id
LEFT JOIN users r ON bsb.runner_id = r.id
WHERE bsb.status IN ('completed', 'confirmed');

-- Grant permissions
GRANT SELECT ON admin_all_transactions TO authenticated;
