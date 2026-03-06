-- Ensure admin_all_transactions view exists (fallback if 20240304 failed).
-- Uses paytoday_transactions so it works regardless of payments table structure.
-- Only creates the view if it does not exist (does not overwrite 20240304 if that succeeded).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'admin_all_transactions') THEN
    CREATE VIEW admin_all_transactions AS
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
        CASE
            WHEN e.id IS NOT NULL THEN 'errand'
            WHEN tb.id IS NOT NULL THEN 'transportation'
            WHEN cb.id IS NOT NULL THEN 'contract'
            WHEN bsb.id IS NOT NULL THEN 'bus'
            ELSE 'unknown'
        END as booking_type,
        CASE
            WHEN e.id IS NOT NULL THEN e.title
            WHEN tb.id IS NOT NULL THEN 'Trip: ' || COALESCE(tb.pickup_location, '') || ' to ' || COALESCE(tb.dropoff_location, '')
            WHEN cb.id IS NOT NULL THEN 'Contract: ' || cb.id::text
            WHEN bsb.id IS NOT NULL THEN 'Bus: ' || COALESCE(bsb.origin_region, '') || ' to ' || COALESCE(bsb.destination_region, '')
            ELSE 'Payment for ' || pt.errand_id::text
        END as title
    FROM paytoday_transactions pt
    LEFT JOIN users c ON pt.customer_id = c.id
    LEFT JOIN users r ON pt.runner_id = r.id
    LEFT JOIN errands e ON pt.errand_id = e.id
    LEFT JOIN transportation_bookings tb ON pt.errand_id = tb.id
    LEFT JOIN contract_bookings cb ON pt.errand_id = cb.id
    LEFT JOIN bus_service_bookings bsb ON pt.errand_id = bsb.id;

    GRANT SELECT ON admin_all_transactions TO authenticated;
    GRANT SELECT ON admin_all_transactions TO service_role;
  END IF;
END $$;
