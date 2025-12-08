-- Create service_routes table and dependencies
-- Run this in your Supabase SQL Editor

-- 1. Create the service_routes table
CREATE TABLE IF NOT EXISTS service_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_name VARCHAR(200) NOT NULL,
  from_location TEXT NOT NULL,
  to_location TEXT NOT NULL,
  distance_km DECIMAL(8, 2),
  estimated_duration_minutes INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_service_routes_name ON service_routes(route_name);
CREATE INDEX IF NOT EXISTS idx_service_routes_locations ON service_routes(from_location, to_location);
CREATE INDEX IF NOT EXISTS idx_service_routes_active ON service_routes(is_active);

-- 3. Add the updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. Add trigger for updated_at
DROP TRIGGER IF EXISTS update_service_routes_updated_at ON service_routes;
CREATE TRIGGER update_service_routes_updated_at 
    BEFORE UPDATE ON service_routes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Enable Row Level Security
ALTER TABLE service_routes ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies
DROP POLICY IF EXISTS "Public can view active routes" ON service_routes;
CREATE POLICY "Public can view active routes" ON service_routes
    FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Admins can manage all routes" ON service_routes;
CREATE POLICY "Admins can manage all routes" ON service_routes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- 7. Insert sample route data
INSERT INTO service_routes (route_name, from_location, to_location, distance_km, estimated_duration_minutes, is_active) VALUES
('Windhoek to Swakopmund', 'Windhoek', 'Swakopmund', 365, 270, true),
('Windhoek to Walvis Bay', 'Windhoek', 'Walvis Bay', 350, 255,  true),
('Windhoek to Oshakati', 'Windhoek', 'Oshakati', 730, 480,  true),
('Windhoek to Rundu', 'Windhoek', 'Rundu', 700, 450,  true),
('Windhoek to Katima Mulilo', 'Windhoek', 'Katima Mulilo', 1200, 720, true),
('Windhoek to Grootfontein', 'Windhoek', 'Grootfontein', 460, 300, true),
('Windhoek to Otjiwarongo', 'Windhoek', 'Otjiwarongo', 250, 180, true),
('Windhoek to Gobabis', 'Windhoek', 'Gobabis', 200, 150, true),
('Windhoek to Mariental', 'Windhoek', 'Mariental', 240, true);

ON CONFLICT (route_name) DO NOTHING;

-- 8. Update transportation_services to reference service_routes
-- First, let's see what transportation_services exist
SELECT 'Current transportation_services:' as status;
SELECT id, name, route_id FROM transportation_services LIMIT 5;

-- 9. Create a mapping function to link existing services to routes
-- This will help if you have existing transportation_services that need route_id
CREATE OR REPLACE FUNCTION link_services_to_routes()
RETURNS void AS $$
DECLARE
    service_record RECORD;
    route_record RECORD;
BEGIN
    -- For each transportation service without a route_id, try to find a matching route
    FOR service_record IN 
        SELECT id, name FROM transportation_services WHERE route_id IS NULL
    LOOP
        -- Try to find a matching route based on service name
        FOR route_record IN 
            SELECT id FROM service_routes 
            WHERE LOWER(route_name) LIKE '%' || LOWER(service_record.name) || '%'
            OR LOWER(service_record.name) LIKE '%' || LOWER(route_name) || '%'
            LIMIT 1
        LOOP
            UPDATE transportation_services 
            SET route_id = route_record.id 
            WHERE id = service_record.id;
            RAISE NOTICE 'Linked service "%" to route ID %', service_record.name, route_record.id;
            EXIT;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 10. Run the linking function
SELECT link_services_to_routes();

-- 11. Verify the setup
SELECT '=== VERIFICATION ===' as status;

-- Check if service_routes table exists and has data
SELECT 
    'service_routes' as table_name,
    COUNT(*) as total_routes,
    COUNT(*) FILTER (WHERE is_active = true) as active_routes
FROM service_routes;

-- Check transportation_services and their routes
SELECT 
    ts.name as service_name,
    ts.is_active as service_active,
    sr.route_name,
    sr.from_location,
    sr.to_location,
    sr.distance_km,
    sr.estimated_duration_minutes
FROM transportation_services ts
LEFT JOIN service_routes sr ON ts.route_id = sr.id
ORDER BY ts.name;

-- 12. Test the exact query that getBusServices uses
SELECT '=== TESTING GETBUS SERVICES QUERY ===' as status;

SELECT 
    ts.*,
    sp.name as provider_name,
    sp.contact_phone as provider_phone,
    sp.contact_email as provider_email,
    sr.route_name,
    sr.from_location,
    sr.to_location
FROM transportation_services ts
LEFT JOIN service_providers sp ON ts.provider_id = sp.id
LEFT JOIN service_routes sr ON ts.route_id = sr.id
WHERE ts.is_active = true
ORDER BY ts.name;

-- 13. Final status
SELECT '=== SETUP COMPLETE ===' as status;

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ service_routes table created and populated successfully!'
        ELSE '❌ Something went wrong with the setup.'
    END as final_status
FROM service_routes;
