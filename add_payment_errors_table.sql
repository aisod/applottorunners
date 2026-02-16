-- Create payment_errors table for logging WebView failures
CREATE TABLE IF NOT EXISTS payment_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    errand_id UUID NOT NULL REFERENCES errands(id) ON DELETE CASCADE,
    payment_type TEXT NOT NULL,
    error_message TEXT NOT NULL,
    additional_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_payment_errors_errand_id ON payment_errors(errand_id);
CREATE INDEX IF NOT EXISTS idx_payment_errors_created_at ON payment_errors(created_at DESC);

-- Enable RLS
ALTER TABLE payment_errors ENABLE ROW LEVEL SECURITY;

-- Allow admins to view all errors
CREATE POLICY payment_errors_admin_view ON payment_errors
    FOR SELECT
    USING (
        auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
    );

-- Allow system to insert errors (via service role)
CREATE POLICY payment_errors_system_insert ON payment_errors
    FOR INSERT
    WITH CHECK (true);

COMMENT ON TABLE payment_errors IS 'Logs PayToday payment errors from WebView for debugging';
