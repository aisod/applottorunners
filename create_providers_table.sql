-- Create providers table
CREATE TABLE IF NOT EXISTS providers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policy for providers table
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;

-- Admin can do everything
CREATE POLICY "Admin can do everything on providers" ON providers
    FOR ALL USING (is_admin());

-- Users can only view active providers
CREATE POLICY "Users can view active providers" ON providers
    FOR SELECT USING (is_active = true);

-- Add updated_at trigger for providers
CREATE OR REPLACE FUNCTION update_providers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER providers_updated_at
    BEFORE UPDATE ON providers
    FOR EACH ROW
    EXECUTE FUNCTION update_providers_updated_at();

-- Update transportation_services table to add new fields
ALTER TABLE transportation_services 
ADD COLUMN IF NOT EXISTS price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS departure_time TIME,
ADD COLUMN IF NOT EXISTS check_in_time TIME,
ADD COLUMN IF NOT EXISTS days_of_week TEXT[] DEFAULT '{}';

-- Add comment to explain days_of_week format
COMMENT ON COLUMN transportation_services.days_of_week IS 'Array of days: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday';

-- Update the existing RLS policies to include the new fields
-- (The existing policies should work with the new fields automatically)

-- Insert some sample providers
INSERT INTO providers (name, location, phone_number) VALUES
    ('Express Transport Co.', 'Nairobi', '+254700123456'),
    ('City Shuttle Services', 'Mombasa', '+254700234567'),
    ('Intercity Bus Lines', 'Kisumu', '+254700345678'),
    ('Airport Transfer Pro', 'Nairobi', '+254700456789'),
    ('Regional Transport Ltd', 'Nakuru', '+254700567890')
ON CONFLICT DO NOTHING;

-- Update some existing transportation services with sample data
UPDATE transportation_services 
SET 
    price = 1500.00,
    departure_time = '08:00:00',
    check_in_time = '07:30:00',
    days_of_week = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
WHERE id IN (SELECT id FROM transportation_services LIMIT 3);

UPDATE transportation_services 
SET 
    price = 2500.00,
    departure_time = '14:00:00',
    check_in_time = '13:30:00',
    days_of_week = ARRAY['Monday', 'Wednesday', 'Friday']
WHERE id IN (SELECT id FROM transportation_services LIMIT 3 OFFSET 3);
