-- PayToday Payment Tracking Schema
-- This script creates tables and functions to track PayToday payment transactions

-- Create enum types for payment tracking
CREATE TYPE payment_type AS ENUM ('first_half', 'second_half', 'admin_payout', 'refund');
CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'refunded');
CREATE TYPE payout_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled');

-- PayToday Transactions Table
-- Tracks all payment transactions made through PayToday
CREATE TABLE IF NOT EXISTS paytoday_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    errand_id UUID NOT NULL REFERENCES errands(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    runner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Payment details
    payment_type payment_type NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'NAD',
    
    -- Transaction status
    status payment_status DEFAULT 'pending',
    transaction_id TEXT, -- PayToday transaction ID
    payment_intent_data JSONB, -- Stores PayToday response data
    
    -- Error tracking
    error_message TEXT,
    error_code TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    -- Indexes for performance
    CONSTRAINT unique_errand_payment_type UNIQUE (errand_id, payment_type)
);

-- Create indexes for faster queries
CREATE INDEX idx_paytoday_transactions_errand_id ON paytoday_transactions(errand_id);
CREATE INDEX idx_paytoday_transactions_customer_id ON paytoday_transactions(customer_id);
CREATE INDEX idx_paytoday_transactions_runner_id ON paytoday_transactions(runner_id);
CREATE INDEX idx_paytoday_transactions_status ON paytoday_transactions(status);
CREATE INDEX idx_paytoday_transactions_created_at ON paytoday_transactions(created_at DESC);

-- Runner Payouts Table
-- Tracks admin-initiated payouts to runners
CREATE TABLE IF NOT EXISTS runner_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    runner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    errand_id UUID NOT NULL REFERENCES errands(id) ON DELETE CASCADE,
    
    -- Payout details
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'NAD',
    
    -- Status tracking
    status payout_status DEFAULT 'pending',
    transaction_id TEXT, -- PayToday payout transaction ID
    payout_method VARCHAR(50) DEFAULT 'paytoday', -- 'paytoday', 'manual', 'bank_transfer'
    
    -- Admin tracking
    initiated_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Additional info
    notes TEXT,
    error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    
    -- Ensure one payout per errand
    CONSTRAINT unique_errand_payout UNIQUE (errand_id)
);

-- Create indexes for runner payouts
CREATE INDEX idx_runner_payouts_runner_id ON runner_payouts(runner_id);
CREATE INDEX idx_runner_payouts_errand_id ON runner_payouts(errand_id);
CREATE INDEX idx_runner_payouts_status ON runner_payouts(status);
CREATE INDEX idx_runner_payouts_created_at ON runner_payouts(created_at DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_paytoday_transactions_updated_at
    BEFORE UPDATE ON paytoday_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_runner_payouts_updated_at
    BEFORE UPDATE ON runner_payouts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to get total paid amount for an errand
CREATE OR REPLACE FUNCTION get_errand_total_paid(p_errand_id UUID)
RETURNS DECIMAL AS $$
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
$$ LANGUAGE plpgsql;

-- Function to get pending payment amount for an errand
CREATE OR REPLACE FUNCTION get_errand_pending_amount(p_errand_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    total_price DECIMAL;
    total_paid DECIMAL;
    pending_amount DECIMAL;
BEGIN
    -- Get total price from errand
    SELECT price_amount INTO total_price
    FROM errands
    WHERE id = p_errand_id;
    
    -- Get total paid
    total_paid := get_errand_total_paid(p_errand_id);
    
    -- Calculate pending
    pending_amount := COALESCE(total_price, 0) - COALESCE(total_paid, 0);
    
    RETURN GREATEST(pending_amount, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to check if errand has pending payments
CREATE OR REPLACE FUNCTION has_pending_payments(p_errand_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    pending_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO pending_count
    FROM paytoday_transactions
    WHERE errand_id = p_errand_id
    AND status IN ('pending', 'processing');
    
    RETURN pending_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Function to get runner total earnings
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
    AND payment_type IN ('first_half', 'second_half');
    
    RETURN total_earnings;
END;
$$ LANGUAGE plpgsql;

-- Function to get runner pending payouts
CREATE OR REPLACE FUNCTION get_runner_pending_payouts(p_runner_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    total_pending DECIMAL;
BEGIN
    SELECT COALESCE(SUM(amount), 0)
    INTO total_pending
    FROM runner_payouts
    WHERE runner_id = p_runner_id
    AND status IN ('pending', 'processing');
    
    RETURN total_pending;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies for paytoday_transactions
ALTER TABLE paytoday_transactions ENABLE ROW LEVEL SECURITY;

-- Customers can view their own transactions
CREATE POLICY paytoday_transactions_customer_view ON paytoday_transactions
    FOR SELECT
    USING (
        auth.uid() = customer_id
        OR auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
    );

-- Runners can view transactions related to their errands
CREATE POLICY paytoday_transactions_runner_view ON paytoday_transactions
    FOR SELECT
    USING (
        auth.uid() = runner_id
        OR auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
    );

-- Only authenticated users can create transactions (via app logic)
CREATE POLICY paytoday_transactions_create ON paytoday_transactions
    FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- Only system/admin can update transaction status
CREATE POLICY paytoday_transactions_update ON paytoday_transactions
    FOR UPDATE
    USING (
        auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
        OR auth.uid() = customer_id
    );

-- RLS Policies for runner_payouts
ALTER TABLE runner_payouts ENABLE ROW LEVEL SECURITY;

-- Runners can view their own payouts
CREATE POLICY runner_payouts_runner_view ON runner_payouts
    FOR SELECT
    USING (
        auth.uid() = runner_id
        OR auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
    );

-- Only admins can create payouts
CREATE POLICY runner_payouts_admin_create ON runner_payouts
    FOR INSERT
    WITH CHECK (
        auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
    );

-- Only admins can update payouts
CREATE POLICY runner_payouts_admin_update ON runner_payouts
    FOR UPDATE
    USING (
        auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON paytoday_transactions TO authenticated;
GRANT SELECT ON runner_payouts TO authenticated;
GRANT INSERT, UPDATE ON runner_payouts TO authenticated;

-- Comments for documentation
COMMENT ON TABLE paytoday_transactions IS 'Tracks all PayToday payment transactions including split payments';
COMMENT ON TABLE runner_payouts IS 'Tracks admin-initiated payouts to runners for completed errands';
COMMENT ON FUNCTION get_errand_total_paid IS 'Returns total amount paid for an errand';
COMMENT ON FUNCTION get_errand_pending_amount IS 'Returns remaining amount to be paid for an errand';
COMMENT ON FUNCTION get_runner_total_earnings IS 'Returns total earnings for a runner from completed errands';
