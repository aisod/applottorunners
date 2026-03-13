-- Restrict admin_all_transactions to admins only.
-- Any authenticated user could previously SELECT from the view; now only users
-- with user_type = 'admin' can read it via the RPC.

-- 1. Function that returns view rows only for admins (SECURITY DEFINER so it can read the view after we revoke SELECT).
CREATE OR REPLACE FUNCTION get_admin_all_transactions()
RETURNS SETOF admin_all_transactions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (SELECT user_type FROM public.users WHERE id = auth.uid()) IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Only admins can access admin_all_transactions';
  END IF;
  RETURN QUERY SELECT * FROM public.admin_all_transactions ORDER BY created_at DESC;
END;
$$;

-- 2. Revoke direct SELECT so only this function (and service_role) can read the view.
REVOKE SELECT ON admin_all_transactions FROM authenticated;

-- 3. Allow authenticated users to call the function; the function enforces admin check.
GRANT EXECUTE ON FUNCTION get_admin_all_transactions() TO authenticated;

COMMENT ON FUNCTION get_admin_all_transactions() IS 'Returns admin_all_transactions rows only for users with user_type = admin.';
