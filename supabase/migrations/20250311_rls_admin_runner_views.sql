-- RLS-style access control for admin_all_transactions, runner_earnings_summary, runner_verification_view.
-- 1) Enable RLS on underlying tables so row-level checks apply at the data source.
-- 2) Revoke direct SELECT on views and expose access via SECURITY DEFINER functions.

-- =============================================================================
-- 0. Enable RLS on underlying tables (views read from these; RLS applies to direct access)
-- =============================================================================

-- users: used by all three views; allow own row + admin all
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_users_select_own" ON public.users;
CREATE POLICY "rls_views_users_select_own" ON public.users
  FOR SELECT USING (id = auth.uid());
DROP POLICY IF EXISTS "rls_views_users_select_admin" ON public.users;
CREATE POLICY "rls_views_users_select_admin" ON public.users
  FOR SELECT USING (
    (SELECT user_type FROM public.users u WHERE u.id = auth.uid()) = 'admin'
  );

-- runner_applications: used by runner_verification_view; allow own row + admin all
ALTER TABLE IF EXISTS public.runner_applications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_runner_apps_select_own" ON public.runner_applications;
CREATE POLICY "rls_views_runner_apps_select_own" ON public.runner_applications
  FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "rls_views_runner_apps_select_admin" ON public.runner_applications;
CREATE POLICY "rls_views_runner_apps_select_admin" ON public.runner_applications
  FOR SELECT USING (
    (SELECT user_type FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- payments: used by admin_all_transactions, runner_earnings_summary
ALTER TABLE IF EXISTS public.payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_payments_select_own" ON public.payments;
CREATE POLICY "rls_views_payments_select_own" ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.errands e
      WHERE e.id = errand_id AND (e.customer_id = auth.uid() OR e.runner_id = auth.uid())
    )
  );
DROP POLICY IF EXISTS "rls_views_payments_select_admin" ON public.payments;
CREATE POLICY "rls_views_payments_select_admin" ON public.payments
  FOR SELECT USING (
    (SELECT user_type FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- errands: used by admin_all_transactions, runner_earnings_summary
ALTER TABLE IF EXISTS public.errands ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_errands_select_own" ON public.errands;
CREATE POLICY "rls_views_errands_select_own" ON public.errands
  FOR SELECT USING (customer_id = auth.uid() OR runner_id = auth.uid());
DROP POLICY IF EXISTS "rls_views_errands_select_admin" ON public.errands;
CREATE POLICY "rls_views_errands_select_admin" ON public.errands
  FOR SELECT USING (
    (SELECT user_type FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- transportation_bookings, contract_bookings, bus_service_bookings: admin_all_transactions, runner_earnings_summary
ALTER TABLE IF EXISTS public.transportation_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_transport_bookings_select_own" ON public.transportation_bookings;
CREATE POLICY "rls_views_transport_bookings_select_own" ON public.transportation_bookings
  FOR SELECT USING (user_id = auth.uid() OR driver_id = auth.uid());
DROP POLICY IF EXISTS "rls_views_transport_bookings_select_admin" ON public.transportation_bookings;
CREATE POLICY "rls_views_transport_bookings_select_admin" ON public.transportation_bookings
  FOR SELECT USING (
    (SELECT user_type FROM public.users WHERE id = auth.uid()) = 'admin'
  );

ALTER TABLE IF EXISTS public.contract_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_contract_bookings_select_own" ON public.contract_bookings;
CREATE POLICY "rls_views_contract_bookings_select_own" ON public.contract_bookings
  FOR SELECT USING (user_id = auth.uid() OR runner_id = auth.uid() OR driver_id = auth.uid());
DROP POLICY IF EXISTS "rls_views_contract_bookings_select_admin" ON public.contract_bookings;
CREATE POLICY "rls_views_contract_bookings_select_admin" ON public.contract_bookings
  FOR SELECT USING (
    (SELECT user_type FROM public.users WHERE id = auth.uid()) = 'admin'
  );

ALTER TABLE IF EXISTS public.bus_service_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_bus_bookings_select_own" ON public.bus_service_bookings;
CREATE POLICY "rls_views_bus_bookings_select_own" ON public.bus_service_bookings
  FOR SELECT USING (user_id = auth.uid() OR runner_id = auth.uid());
DROP POLICY IF EXISTS "rls_views_bus_bookings_select_admin" ON public.bus_service_bookings;
CREATE POLICY "rls_views_bus_bookings_select_admin" ON public.bus_service_bookings
  FOR SELECT USING (
    (SELECT user_type FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- paytoday_transactions: used by runner_earnings_summary
ALTER TABLE IF EXISTS public.paytoday_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rls_views_paytoday_select_admin" ON public.paytoday_transactions;
CREATE POLICY "rls_views_paytoday_select_admin" ON public.paytoday_transactions
  FOR SELECT USING (
    (SELECT user_type FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- =============================================================================
-- 1. admin_all_transactions (admin only – already restricted; ensure no direct SELECT)
-- =============================================================================
REVOKE SELECT ON admin_all_transactions FROM authenticated;
-- Access only via get_admin_all_transactions() which checks user_type = 'admin'.

-- =============================================================================
-- 2. runner_earnings_summary (runners: own row; admins: all rows)
-- =============================================================================
REVOKE SELECT ON runner_earnings_summary FROM authenticated;

CREATE OR REPLACE FUNCTION get_runner_earnings_summary(p_runner_id uuid DEFAULT NULL)
RETURNS SETOF runner_earnings_summary
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_type text;
BEGIN
  SELECT user_type INTO v_user_type FROM public.users WHERE id = auth.uid();

  IF p_runner_id IS NULL THEN
    -- No runner filter: allow only admins to see all rows
    IF v_user_type IS DISTINCT FROM 'admin' THEN
      RAISE EXCEPTION 'Only admins can list all runner earnings';
    END IF;
    RETURN QUERY SELECT * FROM public.runner_earnings_summary;
  ELSE
    -- Filter by runner: caller must be that runner or admin
    IF v_user_type = 'admin' THEN
      RETURN QUERY SELECT * FROM public.runner_earnings_summary WHERE runner_id = p_runner_id;
    ELSIF auth.uid() = p_runner_id THEN
      RETURN QUERY SELECT * FROM public.runner_earnings_summary WHERE runner_id = p_runner_id;
    ELSE
      RAISE EXCEPTION 'Access denied: you can only view your own earnings';
    END IF;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION get_runner_earnings_summary(uuid) TO authenticated;
COMMENT ON FUNCTION get_runner_earnings_summary(uuid) IS 'RLS-style access: runners see own row (pass runner_id); admins see all (pass NULL).';

-- =============================================================================
-- 3. runner_verification_view (admin only)
-- =============================================================================
REVOKE SELECT ON runner_verification_view FROM authenticated;

CREATE OR REPLACE FUNCTION get_runner_verification_view(p_verification_status text DEFAULT NULL)
RETURNS SETOF runner_verification_view
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (SELECT user_type FROM public.users WHERE id = auth.uid()) IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Only admins can access runner verification view';
  END IF;

  IF p_verification_status IS NULL OR p_verification_status = '' THEN
    RETURN QUERY SELECT * FROM public.runner_verification_view ORDER BY applied_at DESC;
  ELSE
    RETURN QUERY
    SELECT * FROM public.runner_verification_view
    WHERE verification_status = p_verification_status
    ORDER BY applied_at DESC;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION get_runner_verification_view(text) TO authenticated;
COMMENT ON FUNCTION get_runner_verification_view(text) IS 'Admin-only: returns runner_verification_view rows; optional filter by verification_status (e.g. pending).';
