-- Add Commission Tracking System
-- This migration adds commission tracking fields to all booking types
-- Company takes 33.3% commission, runners get 66.7%

-- Add commission fields to payments table
ALTER TABLE payments ADD COLUMN IF NOT EXISTS company_commission DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS runner_earnings DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 33.33;

-- Add commission fields to transportation_bookings
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS company_commission DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS runner_earnings DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 33.33;

-- Add driver_id to transportation_bookings if not exists (for tracking who accepted the booking)
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES users(id);
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS runner_id UUID REFERENCES users(id);

-- Add commission fields to contract_bookings
ALTER TABLE contract_bookings ADD COLUMN IF NOT EXISTS company_commission DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE contract_bookings ADD COLUMN IF NOT EXISTS runner_earnings DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE contract_bookings ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 33.33;

-- Add commission fields to bus_service_bookings
ALTER TABLE bus_service_bookings ADD COLUMN IF NOT EXISTS company_commission DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE bus_service_bookings ADD COLUMN IF NOT EXISTS runner_earnings DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE bus_service_bookings ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 33.33;

-- Add runner_id to bus_service_bookings if not exists (for tracking who accepted the booking)
ALTER TABLE bus_service_bookings ADD COLUMN IF NOT EXISTS runner_id UUID REFERENCES users(id);

-- Add runner_id to contract_bookings if not exists (for tracking who accepted the booking)
ALTER TABLE contract_bookings ADD COLUMN IF NOT EXISTS runner_id UUID REFERENCES users(id);
ALTER TABLE contract_bookings ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES users(id);

-- Create function to calculate commission automatically
CREATE OR REPLACE FUNCTION calculate_commission(
    total_amount DECIMAL(10,2),
    commission_rate DECIMAL(5,2) DEFAULT 33.33
)
RETURNS TABLE(
    company_commission DECIMAL(10,2),
    runner_earnings DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY SELECT 
        ROUND(total_amount * (commission_rate / 100), 2) AS company_commission,
        ROUND(total_amount * ((100 - commission_rate) / 100), 2) AS runner_earnings;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create trigger function to auto-calculate commission on payments
CREATE OR REPLACE FUNCTION auto_calculate_payment_commission()
RETURNS TRIGGER AS $$
DECLARE
    calc_result RECORD;
BEGIN
    -- Calculate commission if status is completed
    IF NEW.status = 'completed' AND (NEW.company_commission IS NULL OR NEW.company_commission = 0) THEN
        SELECT * INTO calc_result FROM calculate_commission(NEW.amount, NEW.commission_rate);
        NEW.company_commission := calc_result.company_commission;
        NEW.runner_earnings := calc_result.runner_earnings;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for payments table
DROP TRIGGER IF EXISTS trigger_auto_calculate_payment_commission ON payments;
CREATE TRIGGER trigger_auto_calculate_payment_commission
    BEFORE INSERT OR UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_payment_commission();

-- Create trigger function for transportation bookings
CREATE OR REPLACE FUNCTION auto_calculate_transportation_commission()
RETURNS TRIGGER AS $$
DECLARE
    calc_result RECORD;
BEGIN
    -- Calculate commission when final_price is set and booking is completed
    IF NEW.status IN ('completed', 'confirmed') AND NEW.final_price IS NOT NULL AND 
       (NEW.company_commission IS NULL OR NEW.company_commission = 0) THEN
        SELECT * INTO calc_result FROM calculate_commission(NEW.final_price, NEW.commission_rate);
        NEW.company_commission := calc_result.company_commission;
        NEW.runner_earnings := calc_result.runner_earnings;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for transportation_bookings
DROP TRIGGER IF EXISTS trigger_auto_calculate_transportation_commission ON transportation_bookings;
CREATE TRIGGER trigger_auto_calculate_transportation_commission
    BEFORE INSERT OR UPDATE ON transportation_bookings
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_transportation_commission();

-- Create trigger function for contract bookings
CREATE OR REPLACE FUNCTION auto_calculate_contract_commission()
RETURNS TRIGGER AS $$
DECLARE
    calc_result RECORD;
BEGIN
    -- Calculate commission when final_price is set
    IF NEW.status IN ('completed', 'active', 'confirmed') AND NEW.final_price IS NOT NULL AND 
       (NEW.company_commission IS NULL OR NEW.company_commission = 0) THEN
        SELECT * INTO calc_result FROM calculate_commission(NEW.final_price, NEW.commission_rate);
        NEW.company_commission := calc_result.company_commission;
        NEW.runner_earnings := calc_result.runner_earnings;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for contract_bookings
DROP TRIGGER IF EXISTS trigger_auto_calculate_contract_commission ON contract_bookings;
CREATE TRIGGER trigger_auto_calculate_contract_commission
    BEFORE INSERT OR UPDATE ON contract_bookings
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_contract_commission();

-- Create trigger function for bus service bookings
CREATE OR REPLACE FUNCTION auto_calculate_bus_commission()
RETURNS TRIGGER AS $$
DECLARE
    calc_result RECORD;
    booking_price DECIMAL(10,2);
BEGIN
    -- Calculate commission when price is set and booking is completed
    booking_price := COALESCE(NEW.final_price, NEW.estimated_price);
    IF NEW.status IN ('completed', 'confirmed') AND booking_price IS NOT NULL AND booking_price > 0 AND 
       (NEW.company_commission IS NULL OR NEW.company_commission = 0) THEN
        SELECT * INTO calc_result FROM calculate_commission(booking_price, NEW.commission_rate);
        NEW.company_commission := calc_result.company_commission;
        NEW.runner_earnings := calc_result.runner_earnings;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for bus_service_bookings
DROP TRIGGER IF EXISTS trigger_auto_calculate_bus_commission ON bus_service_bookings;
CREATE TRIGGER trigger_auto_calculate_bus_commission
    BEFORE INSERT OR UPDATE ON bus_service_bookings
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_bus_commission();

-- Create view for runner earnings summary
CREATE OR REPLACE VIEW runner_earnings_summary AS
SELECT 
    u.id AS runner_id,
    u.full_name AS runner_name,
    u.email AS runner_email,
    u.phone AS runner_phone,
    COALESCE(earnings_data.total_bookings, 0) AS total_bookings,
    COALESCE(earnings_data.completed_bookings, 0) AS completed_bookings,
    COALESCE(earnings_data.total_revenue, 0) AS total_revenue,
    COALESCE(earnings_data.total_company_commission, 0) AS total_company_commission,
    COALESCE(earnings_data.total_runner_earnings, 0) AS total_runner_earnings,
    COALESCE(earnings_data.errand_count, 0) AS errand_count,
    COALESCE(earnings_data.errand_revenue, 0) AS errand_revenue,
    COALESCE(earnings_data.errand_earnings, 0) AS errand_earnings,
    COALESCE(earnings_data.transportation_count, 0) AS transportation_count,
    COALESCE(earnings_data.transportation_revenue, 0) AS transportation_revenue,
    COALESCE(earnings_data.transportation_earnings, 0) AS transportation_earnings,
    COALESCE(earnings_data.contract_count, 0) AS contract_count,
    COALESCE(earnings_data.contract_revenue, 0) AS contract_revenue,
    COALESCE(earnings_data.contract_earnings, 0) AS contract_earnings,
    COALESCE(earnings_data.bus_count, 0) AS bus_count,
    COALESCE(earnings_data.bus_revenue, 0) AS bus_revenue,
    COALESCE(earnings_data.bus_earnings, 0) AS bus_earnings
FROM users u
LEFT JOIN (
    SELECT 
        runner_id,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN booking_status IN ('completed', 'confirmed') THEN 1 ELSE 0 END) AS completed_bookings,
        SUM(booking_amount) AS total_revenue,
        SUM(company_commission) AS total_company_commission,
        SUM(runner_earnings) AS total_runner_earnings,
        SUM(CASE WHEN booking_type = 'errand' THEN 1 ELSE 0 END) AS errand_count,
        SUM(CASE WHEN booking_type = 'errand' THEN booking_amount ELSE 0 END) AS errand_revenue,
        SUM(CASE WHEN booking_type = 'errand' THEN runner_earnings ELSE 0 END) AS errand_earnings,
        SUM(CASE WHEN booking_type = 'transportation' THEN 1 ELSE 0 END) AS transportation_count,
        SUM(CASE WHEN booking_type = 'transportation' THEN booking_amount ELSE 0 END) AS transportation_revenue,
        SUM(CASE WHEN booking_type = 'transportation' THEN runner_earnings ELSE 0 END) AS transportation_earnings,
        SUM(CASE WHEN booking_type = 'contract' THEN 1 ELSE 0 END) AS contract_count,
        SUM(CASE WHEN booking_type = 'contract' THEN booking_amount ELSE 0 END) AS contract_revenue,
        SUM(CASE WHEN booking_type = 'contract' THEN runner_earnings ELSE 0 END) AS contract_earnings,
        SUM(CASE WHEN booking_type = 'bus' THEN 1 ELSE 0 END) AS bus_count,
        SUM(CASE WHEN booking_type = 'bus' THEN booking_amount ELSE 0 END) AS bus_revenue,
        SUM(CASE WHEN booking_type = 'bus' THEN runner_earnings ELSE 0 END) AS bus_earnings
    FROM (
        -- Errands via payments
        SELECT 
            p.runner_id,
            'errand' AS booking_type,
            p.status AS booking_status,
            p.amount AS booking_amount,
            COALESCE(p.company_commission, p.amount * 0.3333) AS company_commission,
            COALESCE(p.runner_earnings, p.amount * 0.6667) AS runner_earnings
        FROM payments p
        WHERE p.runner_id IS NOT NULL
        
        UNION ALL
        
        -- Transportation bookings
        SELECT 
            COALESCE(tb.driver_id, tb.runner_id) AS runner_id,
            'transportation' AS booking_type,
            tb.status AS booking_status,
            COALESCE(tb.final_price, tb.estimated_price, 0) AS booking_amount,
            COALESCE(tb.company_commission, tb.final_price * 0.3333, tb.estimated_price * 0.3333, 0) AS company_commission,
            COALESCE(tb.runner_earnings, tb.final_price * 0.6667, tb.estimated_price * 0.6667, 0) AS runner_earnings
        FROM transportation_bookings tb
        WHERE COALESCE(tb.driver_id, tb.runner_id) IS NOT NULL
        
        UNION ALL
        
        -- Contract bookings (check for runner_id or driver_id column)
        SELECT 
            COALESCE(cb.runner_id, cb.driver_id) AS runner_id,
            'contract' AS booking_type,
            cb.status AS booking_status,
            COALESCE(cb.final_price, cb.estimated_price, 0) AS booking_amount,
            COALESCE(cb.company_commission, cb.final_price * 0.3333, cb.estimated_price * 0.3333, 0) AS company_commission,
            COALESCE(cb.runner_earnings, cb.final_price * 0.6667, cb.estimated_price * 0.6667, 0) AS runner_earnings
        FROM contract_bookings cb
        WHERE COALESCE(cb.runner_id, cb.driver_id) IS NOT NULL
        
        UNION ALL
        
        -- Bus service bookings
        SELECT 
            bsb.runner_id,
            'bus' AS booking_type,
            bsb.status AS booking_status,
            COALESCE(bsb.final_price, bsb.estimated_price, 0) AS booking_amount,
            COALESCE(bsb.company_commission, bsb.final_price * 0.3333, bsb.estimated_price * 0.3333, 0) AS company_commission,
            COALESCE(bsb.runner_earnings, bsb.final_price * 0.6667, bsb.estimated_price * 0.6667, 0) AS runner_earnings
        FROM bus_service_bookings bsb
        WHERE bsb.runner_id IS NOT NULL
    ) all_bookings
    GROUP BY runner_id
) earnings_data ON u.id = earnings_data.runner_id
WHERE u.user_type = 'runner' OR u.is_verified = true;

-- Create function to get runner detailed bookings
CREATE OR REPLACE FUNCTION get_runner_detailed_bookings(p_runner_id UUID)
RETURNS TABLE(
    booking_id UUID,
    booking_type TEXT,
    booking_reference TEXT,
    customer_name TEXT,
    booking_date TIMESTAMP WITH TIME ZONE,
    status TEXT,
    amount DECIMAL(10,2),
    company_commission DECIMAL(10,2),
    runner_earnings DECIMAL(10,2),
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Errands
    SELECT 
        e.id AS booking_id,
        'Errand'::TEXT AS booking_type,
        e.id::TEXT AS booking_reference,
        u.full_name AS customer_name,
        e.created_at AS booking_date,
        e.status,
        e.price_amount AS amount,
        ROUND(e.price_amount * 0.3333, 2) AS company_commission,
        ROUND(e.price_amount * 0.6667, 2) AS runner_earnings,
        e.title AS description
    FROM errands e
    JOIN users u ON e.customer_id = u.id
    WHERE e.runner_id = p_runner_id
    
    UNION ALL
    
    -- Transportation bookings
    SELECT 
        tb.id AS booking_id,
        'Transportation'::TEXT AS booking_type,
        tb.booking_reference AS booking_reference,
        u.full_name AS customer_name,
        tb.created_at AS booking_date,
        tb.status,
        COALESCE(tb.final_price, tb.estimated_price) AS amount,
        COALESCE(tb.company_commission, ROUND(COALESCE(tb.final_price, tb.estimated_price) * 0.3333, 2)) AS company_commission,
        COALESCE(tb.runner_earnings, ROUND(COALESCE(tb.final_price, tb.estimated_price) * 0.6667, 2)) AS runner_earnings,
        CONCAT(tb.pickup_location, ' → ', tb.dropoff_location) AS description
    FROM transportation_bookings tb
    JOIN users u ON tb.user_id = u.id
    WHERE COALESCE(tb.driver_id, tb.runner_id) = p_runner_id
    
    UNION ALL
    
    -- Contract bookings
    SELECT 
        cb.id AS booking_id,
        'Contract'::TEXT AS booking_type,
        cb.contract_reference AS booking_reference,
        u.full_name AS customer_name,
        cb.created_at AS booking_date,
        cb.status,
        COALESCE(cb.final_price, cb.estimated_price) AS amount,
        COALESCE(cb.company_commission, ROUND(COALESCE(cb.final_price, cb.estimated_price) * 0.3333, 2)) AS company_commission,
        COALESCE(cb.runner_earnings, ROUND(COALESCE(cb.final_price, cb.estimated_price) * 0.6667, 2)) AS runner_earnings,
        cb.description
    FROM contract_bookings cb
    JOIN users u ON cb.user_id = u.id
    WHERE COALESCE(cb.runner_id, cb.driver_id) = p_runner_id
    
    UNION ALL
    
    -- Bus service bookings
    SELECT 
        bsb.id AS booking_id,
        'Bus Service'::TEXT AS booking_type,
        bsb.id::TEXT AS booking_reference,
        u.full_name AS customer_name,
        bsb.created_at AS booking_date,
        bsb.status,
        COALESCE(bsb.final_price, bsb.estimated_price) AS amount,
        COALESCE(bsb.company_commission, ROUND(COALESCE(bsb.final_price, bsb.estimated_price) * 0.3333, 2)) AS company_commission,
        COALESCE(bsb.runner_earnings, ROUND(COALESCE(bsb.final_price, bsb.estimated_price) * 0.6667, 2)) AS runner_earnings,
        CONCAT('Bus: ', bsb.pickup_location, ' → ', bsb.dropoff_location) AS description
    FROM bus_service_bookings bsb
    JOIN users u ON bsb.user_id = u.id
    WHERE bsb.runner_id = p_runner_id
    
    ORDER BY booking_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_payments_commission ON payments(runner_id, status, company_commission);
CREATE INDEX IF NOT EXISTS idx_transportation_commission ON transportation_bookings(driver_id, status, company_commission);
CREATE INDEX IF NOT EXISTS idx_contract_commission ON contract_bookings(runner_id, status, company_commission);
CREATE INDEX IF NOT EXISTS idx_bus_commission ON bus_service_bookings(runner_id, status, company_commission);

-- Grant permissions to authenticated users to view their own earnings
GRANT SELECT ON runner_earnings_summary TO authenticated;

COMMENT ON VIEW runner_earnings_summary IS 'Summary view of runner earnings with 33.3% company commission and 66.7% runner earnings';
COMMENT ON FUNCTION calculate_commission IS 'Calculates company commission and runner earnings based on total amount';
COMMENT ON FUNCTION get_runner_detailed_bookings IS 'Returns detailed booking list for a specific runner with commission breakdown';

