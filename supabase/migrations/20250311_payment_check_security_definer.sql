-- Fix: Payment check when runner starts errand
-- When customer pays before a runner accepts, paytoday_transactions.runner_id is null.
-- RLS then hides that row from the runner, so get_errand_pending_amount returns full price.
-- Make these functions SECURITY DEFINER so they run with definer rights and can read
-- all transactions for the errand, giving the correct pending amount.

CREATE OR REPLACE FUNCTION get_errand_total_paid(p_errand_id UUID)
RETURNS DECIMAL
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    total_paid DECIMAL;
BEGIN
    SELECT COALESCE(SUM(amount), 0)
    INTO total_paid
    FROM paytoday_transactions
    WHERE errand_id = p_errand_id
    AND status = 'completed';

    RETURN total_paid;
END;
$$;

CREATE OR REPLACE FUNCTION get_errand_pending_amount(p_errand_id UUID)
RETURNS DECIMAL
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    total_price DECIMAL;
    total_paid DECIMAL;
    pending_amount DECIMAL;
BEGIN
    SELECT price_amount INTO total_price
    FROM errands
    WHERE id = p_errand_id;

    total_paid := get_errand_total_paid(p_errand_id);

    pending_amount := COALESCE(total_price, 0) - COALESCE(total_paid, 0);

    RETURN GREATEST(pending_amount, 0);
END;
$$;

COMMENT ON FUNCTION get_errand_total_paid(UUID) IS 'Returns total amount paid for an errand (SECURITY DEFINER so runner can see payments made before they accepted)';
COMMENT ON FUNCTION get_errand_pending_amount(UUID) IS 'Returns remaining amount to be paid for an errand (SECURITY DEFINER so runner can start errand when customer has paid)';
