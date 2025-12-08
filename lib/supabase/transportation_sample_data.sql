-- Sample Data for Transportation System - Namibian Context

-- 1. Service Categories
INSERT INTO service_categories (name, description, icon, color, sort_order) VALUES
('Transportation', 'Travel and transport services across Namibia', 'directions_bus', '#2196F3', 1),
('E-Hailing', 'On-demand ride and shuttle services', 'local_taxi', '#FF9800', 2),
('Logistics', 'Cargo and delivery transportation', 'local_shipping', '#4CAF50', 3);

-- 2. Service Subcategories
INSERT INTO service_subcategories (name, description, icon, sort_order) VALUES
('Bus Services', 'Intercity bus transportation', 'directions_bus', 1),
('Shuttle Services', 'Door-to-door shuttle services', 'airport_shuttle', 2),
('Ride Sharing', 'Individual and group ride sharing', 'local_taxi', 3),
('Airport Transfers', 'Airport pickup and drop-off services', 'flight', 4),
('Cargo Transport', 'Commercial cargo transportation', 'local_shipping', 5),
('Moving Services', 'Household and office moving', 'home', 6);

-- 3. Vehicle Types (Based on promotional image categories)
INSERT INTO vehicle_types (name, capacity, description, features, icon) VALUES
('Sedan', 4, 'Comfortable 4-seater car for city trips', ARRAY['AC', 'Radio', 'GPS'], 'directions_car'),
('Hatchback', 4, 'Compact and fuel-efficient for short trips', ARRAY['AC', 'Radio', 'GPS'], 'directions_car'),
('Minivan', 7, 'Perfect for families and small groups', ARRAY['AC', 'Radio', 'GPS', 'Luggage Space'], 'airport_shuttle'),
('Large Van', 12, 'Spacious van for groups and luggage', ARRAY['AC', 'Radio', 'GPS', 'Extra Luggage'], 'local_shipping'),
('Minibus', 23, 'Medium bus for larger groups', ARRAY['AC', 'Radio', 'GPS', 'Luggage Compartment'], 'directions_bus'),
('Bus', 45, 'Full-size bus for large groups and long distance', ARRAY['AC', 'Radio', 'WiFi', 'Toilet', 'Reclining Seats'], 'directions_bus'),
('Pickup Truck', 3, 'Open cargo vehicle', ARRAY['Radio', 'GPS', 'Cargo Bed'], 'local_shipping'),
('Cargo Van', 2, 'Enclosed cargo vehicle', ARRAY['Radio', 'GPS', 'Large Cargo Space'], 'local_shipping');

-- 4. Towns/Cities in Namibia
INSERT INTO towns (name, region, latitude, longitude) VALUES
('Windhoek', 'Khomas', -22.5609, 17.0658),
('Swakopmund', 'Erongo', -22.6792, 14.5272),
('Walvis Bay', 'Erongo', -22.9575, 14.5053),
('Oshakati', 'Oshana', -17.7886, 15.6982),
('Rundu', 'Kavango East', -17.9336, 19.7647),
('Katima Mulilo', 'Zambezi', -17.5017, 24.2713),
('Grootfontein', 'Otjozondjupa', -19.5689, 18.1178),
('Tsumeb', 'Oshikoto', -19.2306, 17.7136),
('Otjiwarongo', 'Otjozondjupa', -20.4648, 16.6475),
('Gobabis', 'Omaheke', -22.4500, 18.9667),
('Mariental', 'Hardap', -24.6289, 17.9669),
('Keetmanshoop', 'Karas', -26.5858, 18.1464),
('Lüderitz', 'Karas', -26.6481, 15.1594),
('Okahandja', 'Otjozondjupa', -21.9833, 16.9167),
('Rehoboth', 'Hardap', -23.3167, 17.0833);

-- 5. Routes
INSERT INTO routes (name, origin_town_id, destination_town_id, distance_km, estimated_duration_minutes, route_type) VALUES
-- Major intercity routes
('Windhoek to Swakopmund', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Swakopmund'), 
 365, 270, 'intercity'),
('Windhoek to Walvis Bay', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Walvis Bay'), 
 350, 255, 'intercity'),
('Windhoek to Oshakati', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Oshakati'), 
 730, 480, 'intercity'),
('Windhoek to Rundu', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Rundu'), 
 700, 450, 'intercity'),
('Windhoek to Katima Mulilo', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Katima Mulilo'), 
 1200, 720, 'intercity'),
('Windhoek to Grootfontein', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Grootfontein'), 
 460, 300, 'intercity'),
('Windhoek to Otjiwarongo', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Otjiwarongo'), 
 250, 180, 'intercity'),
('Windhoek to Gobabis', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Gobabis'), 
 200, 150, 'intercity'),
('Windhoek to Mariental', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Mariental'), 
 240, 165, 'intercity'),
('Windhoek to Keetmanshoop', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Keetmanshoop'), 
 485, 330, 'intercity'),
-- Local/shuttle routes
('Windhoek Airport Transfer', 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 (SELECT id FROM towns WHERE name = 'Windhoek'), 
 45, 30, 'airport'),
('Swakopmund Local Shuttle', 
 (SELECT id FROM towns WHERE name = 'Swakopmund'), 
 (SELECT id FROM towns WHERE name = 'Walvis Bay'), 
 30, 25, 'local');

-- 6. Service Providers
INSERT INTO service_providers (name, description, contact_phone, contact_email, license_number, rating, total_reviews, is_verified) VALUES
('Intercape Mainliner', 'Leading intercity bus service in Namibia', '+264-61-227847', 'info@intercape.co.za', 'IC001', 4.5, 1250, true),
('Windhoek Express', 'Premium shuttle and bus services', '+264-61-123456', 'info@windhoekexpress.com.na', 'WE002', 4.2, 890, true),
('Desert Express Transport', 'Specialized desert and coastal routes', '+264-64-205678', 'bookings@desertexpress.na', 'DE003', 4.0, 567, true),
('Capital City Shuttles', 'Local Windhoek shuttle services', '+264-61-987654', 'shuttles@capitalcity.na', 'CC004', 4.3, 432, true),
('Northern Express', 'Services to northern regions', '+264-65-123789', 'north@express.na', 'NE005', 3.9, 234, true),
('Coastal Connections', 'Swakopmund and Walvis Bay services', '+264-64-567890', 'coast@connections.na', 'CC006', 4.1, 678, true);

-- 7. Transportation Services
INSERT INTO transportation_services (subcategory_id, provider_id, vehicle_type_id, route_id, name, description, features, operating_days, is_home_pickup, pickup_radius_km, advance_booking_hours) VALUES
-- Bus Services
((SELECT id FROM service_subcategories WHERE name = 'Bus Services'),
 (SELECT id FROM service_providers WHERE name = 'Intercape Mainliner'),
 (SELECT id FROM vehicle_types WHERE name = 'Bus'),
 (SELECT id FROM routes WHERE name = 'Windhoek to Swakopmund'),
 'Windhoek-Swakopmund Express', 
 'Daily express bus service between Windhoek and Swakopmund',
 ARRAY['WiFi', 'AC', 'Toilet', 'Refreshments'],
 '{1,2,3,4,5,6,7}', false, 0, 2),

((SELECT id FROM service_subcategories WHERE name = 'Bus Services'),
 (SELECT id FROM service_providers WHERE name = 'Intercape Mainliner'),
 (SELECT id FROM vehicle_types WHERE name = 'Bus'),
 (SELECT id FROM routes WHERE name = 'Windhoek to Oshakati'),
 'Windhoek-Oshakati Service', 
 'Regular service to northern Namibia',
 ARRAY['AC', 'Toilet', 'Luggage'],
 '{1,3,5,7}', false, 0, 4),

-- Shuttle Services
((SELECT id FROM service_subcategories WHERE name = 'Shuttle Services'),
 (SELECT id FROM service_providers WHERE name = 'Capital City Shuttles'),
 (SELECT id FROM vehicle_types WHERE name = 'Minivan'),
 (SELECT id FROM routes WHERE name = 'Windhoek to Swakopmund'),
 'Premium Windhoek-Swakopmund Shuttle', 
 'Door-to-door shuttle service with home pickup',
 ARRAY['AC', 'WiFi', 'Luggage'],
 '{1,2,3,4,5,6,7}', true, 15, 1),

((SELECT id FROM service_subcategories WHERE name = 'Shuttle Services'),
 (SELECT id FROM service_providers WHERE name = 'Capital City Shuttles'),
 (SELECT id FROM vehicle_types WHERE name = 'Sedan'),
 (SELECT id FROM routes WHERE name = 'Windhoek Airport Transfer'),
 'Airport Transfer Service', 
 'Quick airport transfers within Windhoek',
 ARRAY['AC', 'GPS', 'Luggage'],
 '{1,2,3,4,5,6,7}', true, 25, 0),

((SELECT id FROM service_subcategories WHERE name = 'Shuttle Services'),
 (SELECT id FROM service_providers WHERE name = 'Windhoek Express'),
 (SELECT id FROM vehicle_types WHERE name = 'Large Van'),
 (SELECT id FROM routes WHERE name = 'Windhoek to Otjiwarongo'),
 'Windhoek-Otjiwarongo Van Service', 
 'Comfortable van service to Otjiwarongo',
 ARRAY['AC', 'Radio', 'Extra Luggage'],
 '{1,2,3,4,5,6}', true, 10, 2),

((SELECT id FROM service_subcategories WHERE name = 'Shuttle Services'),
 (SELECT id FROM service_providers WHERE name = 'Desert Express Transport'),
 (SELECT id FROM vehicle_types WHERE name = 'Minibus'),
 (SELECT id FROM routes WHERE name = 'Windhoek to Walvis Bay'),
 'Desert Express Mini Bus', 
 'Mini bus service to coastal areas',
 ARRAY['AC', 'Radio', 'Scenic Route'],
 '{1,2,3,4,5,6,7}', false, 0, 3);

-- 8. Service Schedules
INSERT INTO service_schedules (service_id, departure_time, arrival_time, days_of_week) VALUES
-- Windhoek-Swakopmund Express (daily)
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Swakopmund Express'), '06:00', '10:30', '{1,2,3,4,5,6,7}'),
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Swakopmund Express'), '14:00', '18:30', '{1,2,3,4,5,6,7}'),

-- Windhoek-Oshakati Service (Mon, Wed, Fri, Sun)
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Oshakati Service'), '07:00', '15:00', '{1,3,5,7}'),

-- Shuttle services (multiple times daily)
((SELECT id FROM transportation_services WHERE name = 'Premium Windhoek-Swakopmund Shuttle'), '06:00', '10:30', '{1,2,3,4,5,6,7}'),
((SELECT id FROM transportation_services WHERE name = 'Premium Windhoek-Swakopmund Shuttle'), '10:00', '14:30', '{1,2,3,4,5,6,7}'),
((SELECT id FROM transportation_services WHERE name = 'Premium Windhoek-Swakopmund Shuttle'), '14:00', '18:30', '{1,2,3,4,5,6,7}'),

-- Airport transfers (every hour)
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), '05:00', '05:30', '{1,2,3,4,5,6,7}'),
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), '06:00', '06:30', '{1,2,3,4,5,6,7}'),
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), '07:00', '07:30', '{1,2,3,4,5,6,7}'),
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), '08:00', '08:30', '{1,2,3,4,5,6,7}'),

-- Van services
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Otjiwarongo Van Service'), '08:00', '11:00', '{1,2,3,4,5,6}'),
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Otjiwarongo Van Service'), '16:00', '19:00', '{1,2,3,4,5,6}'),

-- Mini bus
((SELECT id FROM transportation_services WHERE name = 'Desert Express Mini Bus'), '07:30', '11:45', '{1,2,3,4,5,6,7}'),
((SELECT id FROM transportation_services WHERE name = 'Desert Express Mini Bus'), '15:30', '19:45', '{1,2,3,4,5,6,7}');

-- 9. Service Pricing (Admin-fixed prices)
INSERT INTO service_pricing (service_id, pricing_type, base_price, pickup_fee, minimum_fare, currency) VALUES
-- Bus Services (fixed prices)
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Swakopmund Express'), 'fixed', 250.00, 0.00, 250.00, 'NAD'),
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Oshakati Service'), 'fixed', 400.00, 0.00, 400.00, 'NAD'),

-- Shuttle Services (fixed with pickup fees)
((SELECT id FROM transportation_services WHERE name = 'Premium Windhoek-Swakopmund Shuttle'), 'fixed', 350.00, 50.00, 350.00, 'NAD'),
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), 'fixed', 150.00, 25.00, 150.00, 'NAD'),
((SELECT id FROM transportation_services WHERE name = 'Windhoek-Otjiwarongo Van Service'), 'fixed', 200.00, 30.00, 200.00, 'NAD'),
((SELECT id FROM transportation_services WHERE name = 'Desert Express Mini Bus'), 'fixed', 300.00, 0.00, 300.00, 'NAD');

-- 10. Distance-based pricing tiers for flexible services
INSERT INTO pricing_tiers (service_id, min_distance_km, max_distance_km, price, tier_name) VALUES
-- Airport transfers by distance
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), 0, 10, 150.00, 'City Center'),
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), 10, 20, 200.00, 'Suburbs'),
((SELECT id FROM transportation_services WHERE name = 'Airport Transfer Service'), 20, 35, 250.00, 'Outer Areas');

-- Sample booking reference generator
CREATE OR REPLACE FUNCTION generate_booking_reference()
RETURNS TEXT AS $$
BEGIN
    RETURN 'LR' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Update booking reference trigger
CREATE OR REPLACE FUNCTION set_booking_reference()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.booking_reference IS NULL THEN
        NEW.booking_reference := generate_booking_reference();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_transportation_booking_reference 
    BEFORE INSERT ON transportation_bookings 
    FOR EACH ROW EXECUTE FUNCTION set_booking_reference(); 