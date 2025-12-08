-- Insert Basic Data for Transportation System
-- Run this to populate your database with sample data

-- 1. Insert Service Categories
INSERT INTO service_categories (name, description, icon, color, sort_order) VALUES
('Transportation', 'Travel and transport services across Namibia', 'directions_bus', '#2196F3', 1),
('E-Hailing', 'On-demand ride and shuttle services', 'local_taxi', '#FF9800', 2),
('Logistics', 'Cargo and delivery transportation', 'local_shipping', '#4CAF50', 3)
ON CONFLICT (name) DO NOTHING;

-- 2. Insert Service Subcategories
INSERT INTO service_subcategories (name, description, icon, sort_order) VALUES
('Bus Services', 'Intercity bus transportation', 'directions_bus', 1),
('Shuttle Services', 'Door-to-door shuttle services', 'airport_shuttle', 2),
('Ride Sharing', 'Individual and group ride sharing', 'local_taxi', 3),
('Airport Transfers', 'Airport pickup and drop-off services', 'flight', 4),
('Cargo Transport', 'Commercial cargo transportation', 'local_shipping', 5),
('Moving Services', 'Household and office moving', 'home', 6)
ON CONFLICT (name) DO NOTHING;

-- 3. Insert Vehicle Types
INSERT INTO vehicle_types (name, capacity, description, features, icon) VALUES
('Sedan', 4, 'Comfortable 4-seater car for city trips', ARRAY['AC', 'Radio', 'GPS'], 'directions_car'),
('Minivan', 7, 'Perfect for families and small groups', ARRAY['AC', 'Radio', 'GPS', 'Luggage Space'], 'airport_shuttle'),
('Minibus', 23, 'Medium bus for larger groups', ARRAY['AC', 'Radio', 'GPS', 'Luggage Compartment'], 'directions_bus'),
('Bus', 45, 'Full-size bus for large groups and long distance', ARRAY['AC', 'Radio', 'WiFi', 'Toilet', 'Reclining Seats'], 'directions_bus')
ON CONFLICT (name) DO NOTHING;

-- 4. Insert Towns
INSERT INTO towns (name, region, country) VALUES
('Windhoek', 'Khomas', 'Namibia'),
('Swakopmund', 'Erongo', 'Namibia'),
('Walvis Bay', 'Erongo', 'Namibia'),
('Oshakati', 'Oshana', 'Namibia'),
('Rundu', 'Kavango East', 'Namibia')
ON CONFLICT (name) DO NOTHING;

-- 5. Insert Routes
INSERT INTO routes (name, origin_town_id, destination_town_id, distance_km, estimated_duration_minutes, route_type) VALUES
('Windhoek to Swakopmund', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Swakopmund'), 
 365, 270, 'intercity'),
('Windhoek to Walvis Bay', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Walvis Bay'), 
 350, 255, 'intercity')
ON CONFLICT (origin_town_id, destination_town_id, route_type) DO NOTHING;

-- 6. Insert Service Providers
INSERT INTO service_providers (name, description, contact_phone, is_verified) VALUES
('Namibia Transport Co.', 'Reliable intercity transportation', '+264 61 123 456', true),
('City Shuttle Services', 'Local and airport shuttle services', '+264 61 234 567', true),
('Express Logistics', 'Cargo and delivery services', '+264 61 345 678', true)
ON CONFLICT (name) DO NOTHING;

-- 7. Insert Transportation Services
INSERT INTO transportation_services (subcategory_id, provider_id, vehicle_type_id, route_id, name, description) VALUES
((SELECT id FROM service_subcategories WHERE name = 'Bus Services'), 
 (SELECT id FROM service_providers WHERE name = 'Namibia Transport Co.'),
 (SELECT id FROM vehicle_types WHERE name = 'Bus'),
 (SELECT id FROM routes WHERE name = 'Windhoek to Swakopmund'),
 'Windhoek-Swakopmund Express', 'Daily bus service to Swakopmund')
ON CONFLICT DO NOTHING;

-- 8. Insert Sample Transportation Bookings
INSERT INTO transportation_bookings (user_id, service_id, booking_date, booking_time, passenger_count, status) VALUES
('00000000-0000-0000-0000-000000000001', 
 (SELECT id FROM transportation_services WHERE name = 'Windhoek-Swakopmund Express'),
 '2024-01-15', '08:00:00', 2, 'confirmed')
ON CONFLICT DO NOTHING;

-- Verify the data was inserted
SELECT 'Categories' as table_name, COUNT(*) as count FROM service_categories
UNION ALL
SELECT 'Subcategories', COUNT(*) FROM service_subcategories
UNION ALL
SELECT 'Vehicle Types', COUNT(*) FROM vehicle_types
UNION ALL
SELECT 'Towns', COUNT(*) FROM towns
UNION ALL
SELECT 'Routes', COUNT(*) FROM routes
UNION ALL
SELECT 'Providers', COUNT(*) FROM service_providers
UNION ALL
SELECT 'Services', COUNT(*) FROM transportation_services
UNION ALL
SELECT 'Bookings', COUNT(*) FROM transportation_bookings;
