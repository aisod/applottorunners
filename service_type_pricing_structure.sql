-- Service Type Pricing Structure
-- This file documents how service-type-specific pricing is stored in the database
-- No migration needed - pricing_modifiers JSONB field already exists in errands table

-- ================================================================
-- PRICING MODIFIERS JSONB STRUCTURE
-- ================================================================

-- The pricing_modifiers column in the errands table stores detailed pricing information
-- as a JSON object with the following structure:

/*
{
  "base_price": 0.00,              -- Base category price from services table (reference)
  "service_type_price": 250.00,    -- Actual price charged for specific service type
  "service_type": "renewal",        -- Service type identifier
  "user_type": "individual",        -- User type (individual/business)
  "service_option": "collect_and_deliver"  -- Optional: service option (if applicable)
}
*/

-- ================================================================
-- SERVICE TYPE PRICES
-- ================================================================

-- LICENSE DISCS CATEGORY
-- -----------------------
-- Individual Users:
--   - renewal: N$250
--   - registration: N$1500
--
-- Business Users:
--   - renewal: N$350
--   - registration: N$2100

-- DOCUMENT SERVICES CATEGORY
-- ---------------------------
-- Individual Users:
--   - application_submission: N$200
--   - certification: N$150
--
-- Business Users:
--   - application_submission: N$280
--   - certification: N$210

-- ================================================================
-- QUERY EXAMPLES
-- ================================================================

-- Get all errands with service type pricing breakdown
COMMENT ON COLUMN errands.pricing_modifiers IS 
'JSONB field storing pricing breakdown: base_price, service_type_price, service_type, user_type, service_option';

-- Example query to extract service type pricing
SELECT 
    id,
    title,
    category,
    service_type,
    price_amount,
    calculated_price,
    pricing_modifiers->>'service_type_price' as service_type_price,
    pricing_modifiers->>'service_type' as pricing_service_type,
    pricing_modifiers->>'user_type' as user_type,
    pricing_modifiers->>'service_option' as service_option,
    pricing_modifiers->>'base_price' as base_category_price
FROM errands
WHERE pricing_modifiers IS NOT NULL;

-- Get revenue breakdown by service type
SELECT 
    category,
    service_type,
    pricing_modifiers->>'user_type' as user_type,
    COUNT(*) as booking_count,
    SUM(price_amount) as total_revenue,
    ROUND(SUM(price_amount * 0.3333), 2) as company_commission,
    ROUND(SUM(price_amount * 0.6667), 2) as runner_earnings,
    AVG(price_amount) as avg_booking_value
FROM errands
WHERE status IN ('completed', 'accepted', 'in_progress')
    AND runner_id IS NOT NULL
    AND pricing_modifiers IS NOT NULL
GROUP BY category, service_type, pricing_modifiers->>'user_type'
ORDER BY total_revenue DESC;

-- Get service type breakdown for a specific category
SELECT 
    service_type,
    pricing_modifiers->>'user_type' as user_type,
    COUNT(*) as count,
    SUM(price_amount) as revenue
FROM errands
WHERE category = 'license_discs'
    AND status = 'completed'
    AND pricing_modifiers IS NOT NULL
GROUP BY service_type, pricing_modifiers->>'user_type'
ORDER BY service_type, user_type;

-- Example results for license_discs:
-- service_type  | user_type   | count | revenue
-- renewal       | individual  | 10    | 2500.00
-- renewal       | business    | 5     | 1750.00
-- registration  | individual  | 3     | 4500.00
-- registration  | business    | 2     | 4200.00

-- ================================================================
-- INDEXING FOR PERFORMANCE
-- ================================================================

-- Create GIN index on pricing_modifiers for faster JSONB queries
CREATE INDEX IF NOT EXISTS idx_errands_pricing_modifiers 
ON errands USING GIN (pricing_modifiers);

-- Create index on service_type for faster filtering
CREATE INDEX IF NOT EXISTS idx_errands_service_type 
ON errands(service_type) 
WHERE service_type IS NOT NULL;

-- ================================================================
-- VALIDATION FUNCTION
-- ================================================================

-- Function to validate pricing_modifiers structure
CREATE OR REPLACE FUNCTION validate_pricing_modifiers()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if pricing_modifiers has required fields when present
    IF NEW.pricing_modifiers IS NOT NULL THEN
        IF NOT (
            NEW.pricing_modifiers ? 'service_type_price' AND
            NEW.pricing_modifiers ? 'service_type' AND
            NEW.pricing_modifiers ? 'user_type'
        ) THEN
            RAISE EXCEPTION 'pricing_modifiers must contain service_type_price, service_type, and user_type';
        END IF;
        
        -- Validate that price_amount matches service_type_price
        IF NEW.price_amount != (NEW.pricing_modifiers->>'service_type_price')::DECIMAL THEN
            RAISE WARNING 'price_amount does not match pricing_modifiers.service_type_price';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Optionally create trigger to validate on insert/update
-- (Commented out to avoid strict enforcement during development)
-- CREATE TRIGGER validate_pricing_modifiers_trigger
-- BEFORE INSERT OR UPDATE ON errands
-- FOR EACH ROW
-- EXECUTE FUNCTION validate_pricing_modifiers();

-- ================================================================
-- HELPER VIEWS
-- ================================================================

-- Create a view for easy access to service type pricing details
CREATE OR REPLACE VIEW errand_pricing_details AS
SELECT 
    e.id,
    e.customer_id,
    e.runner_id,
    e.title,
    e.description,
    e.category,
    e.service_type,
    e.price_amount,
    e.calculated_price,
    e.status,
    e.created_at,
    e.completed_at,
    (e.pricing_modifiers->>'base_price')::DECIMAL as base_price,
    (e.pricing_modifiers->>'service_type_price')::DECIMAL as service_type_price,
    e.pricing_modifiers->>'service_type' as pricing_service_type,
    e.pricing_modifiers->>'user_type' as user_type,
    e.pricing_modifiers->>'service_option' as service_option,
    ROUND(e.price_amount * 0.3333, 2) as company_commission,
    ROUND(e.price_amount * 0.6667, 2) as runner_earnings
FROM errands e;

-- Grant access to the view
GRANT SELECT ON errand_pricing_details TO authenticated;

-- ================================================================
-- REPORTING QUERIES
-- ================================================================

-- Monthly revenue by service type
SELECT 
    DATE_TRUNC('month', created_at) as month,
    category,
    service_type,
    COUNT(*) as bookings,
    SUM(price_amount) as revenue
FROM errands
WHERE status = 'completed'
    AND runner_id IS NOT NULL
GROUP BY DATE_TRUNC('month', created_at), category, service_type
ORDER BY month DESC, revenue DESC;

-- Top earning service types
SELECT 
    category,
    service_type,
    pricing_modifiers->>'user_type' as user_type,
    COUNT(*) as total_bookings,
    SUM(price_amount) as total_revenue,
    AVG(price_amount) as avg_price,
    SUM(ROUND(price_amount * 0.6667, 2)) as runner_earnings,
    SUM(ROUND(price_amount * 0.3333, 2)) as company_commission
FROM errands
WHERE status = 'completed'
    AND runner_id IS NOT NULL
    AND pricing_modifiers IS NOT NULL
GROUP BY category, service_type, pricing_modifiers->>'user_type'
ORDER BY total_revenue DESC
LIMIT 10;

