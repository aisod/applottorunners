-- Refactor Payment System: Single Upfront Payment and Runner Wallet

-- 1. Update payment_type enum to include 'full_payment'
-- Note: PostgreSQL doesn't allow adding to enum in a transaction easily in some environments, 
-- but Supabase/Postgres 12+ supports ALTER TYPE ... ADD VALUE.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_type') THEN
        CREATE TYPE payment_type AS ENUM ('first_half', 'second_half', 'full_payment', 'admin_payout');
    ELSE
        IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_enum e ON t.oid = e.enumtypid WHERE t.typname = 'payment_type' AND e.enumlabel = 'full_payment') THEN
            ALTER TYPE payment_type ADD VALUE 'full_payment';
        END IF;
    END IF;
END $$;

-- 2. Add payment_status to errands table to track escrow state
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'errand_payment_status') THEN
        CREATE TYPE errand_payment_status AS ENUM ('unpaid', 'in_escrow', 'released_to_runner', 'refunded');
    END IF;
END $$;

ALTER TABLE errands 
ADD COLUMN IF NOT EXISTS payment_status errand_payment_status DEFAULT 'unpaid';

-- Add payment_status to transport tables
ALTER TABLE transportation_bookings 
ADD COLUMN IF NOT EXISTS payment_status errand_payment_status DEFAULT 'unpaid';

ALTER TABLE contract_bookings 
ADD COLUMN IF NOT EXISTS payment_status errand_payment_status DEFAULT 'unpaid';

ALTER TABLE bus_service_bookings 
ADD COLUMN IF NOT EXISTS payment_status errand_payment_status DEFAULT 'unpaid';

-- 3. Create withdrawal_requests table
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    runner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'NAD',
    status payout_status DEFAULT 'pending',
    notes TEXT,
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    processed_by UUID REFERENCES users(id)
);

-- 4. Enable RLS on withdrawal_requests
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Runners can view and create their own withdrawal requests
CREATE POLICY withdrawal_requests_runner_all ON withdrawal_requests
    FOR ALL
    USING (auth.uid() = runner_id)
    WITH CHECK (auth.uid() = runner_id);

-- Admins can view and update all withdrawal requests
CREATE POLICY withdrawal_requests_admin_all ON withdrawal_requests
    FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND user_type = 'admin'));

-- 5. Trigger for updated_at on withdrawal_requests
CREATE TRIGGER update_withdrawal_requests_updated_at
    BEFORE UPDATE ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 6. Update get_runner_total_earnings to include full_payment
CREATE OR REPLACE FUNCTION get_runner_total_earnings(p_runner_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    total_earnings DECIMAL;
BEGIN
    SELECT COALESCE(SUM(amount), 0)
    INTO total_earnings
    FROM paytoday_transactions
    WHERE runner_id = p_runner_id
    AND status = 'completed'
    AND payment_type IN ('first_half', 'second_half', 'full_payment');
    
    RETURN total_earnings;
END;
$$ LANGUAGE plpgsql;

-- 7. Function to get runner withdrawable balance
-- (Total released earnings - total processed withdrawals)
CREATE OR REPLACE FUNCTION get_runner_withdrawable_balance(p_runner_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    total_released DECIMAL;
    total_withdrawn DECIMAL;
BEGIN
    -- Only count errands where payment has been released to runner
    SELECT COALESCE(SUM(amount * 0.667), 0) -- Assuming 66.7% goes to runner if amount is total booking
    INTO total_released
    FROM paytoday_transactions pt
    JOIN errands e ON pt.errand_id = e.id
    WHERE e.runner_id = p_runner_id
    AND pt.status = 'completed'
    AND e.payment_status = 'released_to_runner';

    SELECT COALESCE(SUM(amount), 0)
    INTO total_withdrawn
    FROM withdrawal_requests
    WHERE runner_id = p_runner_id
    AND status IN ('approved', 'completed');
    
    RETURN GREATEST(total_released - total_withdrawn, 0);
END;
$$ LANGUAGE plpgsql;
