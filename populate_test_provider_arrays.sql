-- Populate test data for transportation services with array-based multi-provider support
-- This script adds sample providers and associates them with services using the array structure

-- First, ensure we have some basic data
-- Insert sample providers if they don't exist
INSERT INTO service_providers (name, description, contact_phone, contact_email, rating, total_reviews, is_verified, is_active) VALUES
('Intercape Mainliner', 'Premium intercity bus service', '+264-61-12345', 'info@intercape.com.na', 4.5, 120, true, true),
('City Shuttle Services', 'Local and airport shuttle service', '+264-61-23456', 'bookings@cityshuttle.na', 4.2, 85, true, true),
('Windhoek Express', 'Express routes within Windhoek region', '+264-61-34567', 'contact@windhoeexpress.na', 4.0, 60, true, true),
('Desert Express Transport', 'Luxury coach service', '+264-61-45678', 'support@desertexpress.na', 4.8, 200, true, true)
ON CONFLICT (name) DO NOTHING;

-- Insert or update transportation services with array-based provider data
-- Service 1: Windhoek-okahandja with multiple providers
INSERT INTO transportation_services (
    name, 
    description, 
    is_active,
    provider_ids,
    prices,
    departure_times,
    check_in_times,
    provider_operating_days
) VALUES (
    'Windhoek-okahandja',
    'Windhoek → Luderitz',
    true,
    ARRAY[
        (SELECT id FROM service_providers WHERE name = 'Intercape Mainliner'),
        (SELECT id FROM service_providers WHERE name = 'City Shuttle Services')
    ],
    ARRAY[12.00, 15.00],
    ARRAY['18:00:00'::time, '19:00:00'::time],
    ARRAY['17:00:00'::time, '18:30:00'::time],
    ARRAY[
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        ARRAY['Monday', 'Wednesday', 'Friday', 'Sunday']
    ]
) ON CONFLICT (name) DO UPDATE SET
    provider_ids = EXCLUDED.provider_ids,
    prices = EXCLUDED.prices,
    departure_times = EXCLUDED.departure_times,
    check_in_times = EXCLUDED.check_in_times,
    provider_operating_days = EXCLUDED.provider_operating_days;

-- Service 2: jjj with providers
INSERT INTO transportation_services (
    name, 
    description, 
    is_active,
    provider_ids,
    prices,
    departure_times,
    check_in_times,
    provider_operating_days
) VALUES (
    'jjj',
    'Windhoek → Walvis Bay',
    true,
    ARRAY[
        (SELECT id FROM service_providers WHERE name = 'Windhoek Express'),
        (SELECT id FROM service_providers WHERE name = 'Desert Express Transport')
    ],
    ARRAY[12.00, 18.00],
    ARRAY['00:00:00'::time, '06:00:00'::time],
    ARRAY['08:56:00'::time, '05:30:00'::time],
    ARRAY[
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        ARRAY['Saturday', 'Sunday']
    ]
) ON CONFLICT (name) DO UPDATE SET
    provider_ids = EXCLUDED.provider_ids,
    prices = EXCLUDED.prices,
    departure_times = EXCLUDED.departure_times,
    check_in_times = EXCLUDED.check_in_times,
    provider_operating_days = EXCLUDED.provider_operating_days;

-- Service 3: hhh with single provider
INSERT INTO transportation_services (
    name, 
    description, 
    is_active,
    provider_ids,
    prices,
    departure_times,
    check_in_times,
    provider_operating_days
) VALUES (
    'hhh',
    'Windhoek → Luderitz',
    true,
    ARRAY[
        (SELECT id FROM service_providers WHERE name = 'Intercape Mainliner')
    ],
    ARRAY[25.00],
    ARRAY['10:00:00'::time],
    ARRAY['09:30:00'::time],
    ARRAY[
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    ]
) ON CONFLICT (name) DO UPDATE SET
    provider_ids = EXCLUDED.provider_ids,
    prices = EXCLUDED.prices,
    departure_times = EXCLUDED.departure_times,
    check_in_times = EXCLUDED.check_in_times,
    provider_operating_days = EXCLUDED.provider_operating_days;

-- Service 4: Bus Transport to Windhoek with providers
INSERT INTO transportation_services (
    name, 
    description, 
    is_active,
    provider_ids,
    prices,
    departure_times,
    check_in_times,
    provider_operating_days
) VALUES (
    'Bus Transport to Windhoek',
    'Various routes to Windhoek',
    true,
    ARRAY[
        (SELECT id FROM service_providers WHERE name = 'Desert Express Transport'),
        (SELECT id FROM service_providers WHERE name = 'City Shuttle Services'),
        (SELECT id FROM service_providers WHERE name = 'Windhoek Express')
    ],
    ARRAY[250.00, 180.00, 200.00],
    ARRAY['07:00:00'::time, '08:30:00'::time, '10:00:00'::time],
    ARRAY['09:00:00'::time, '08:00:00'::time, '09:30:00'::time],
    ARRAY[
        ARRAY['Monday', 'Wednesday', 'Friday'],
        ARRAY['Tuesday', 'Thursday', 'Saturday'],
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    ]
) ON CONFLICT (name) DO UPDATE SET
    provider_ids = EXCLUDED.provider_ids,
    prices = EXCLUDED.prices,
    departure_times = EXCLUDED.departure_times,
    check_in_times = EXCLUDED.check_in_times,
    provider_operating_days = EXCLUDED.provider_operating_days;

-- Create a service route if it doesn't exist
INSERT INTO service_routes (route_name, from_location, to_location, is_active) VALUES
('Windhoek-Luderitz', 'Windhoek', 'Luderitz', true),
('Windhoek-Walvis Bay', 'Windhoek', 'Walvis Bay', true),
('Various-Windhoek', 'Various Locations', 'Windhoek', true)
ON CONFLICT (route_name) DO NOTHING;

-- Update services to link with routes
UPDATE transportation_services 
SET route_id = (SELECT id FROM service_routes WHERE route_name = 'Windhoek-Luderitz' LIMIT 1)
WHERE name IN ('Windhoek-okahandja', 'hhh');

UPDATE transportation_services 
SET route_id = (SELECT id FROM service_routes WHERE route_name = 'Windhoek-Walvis Bay' LIMIT 1)
WHERE name = 'jjj';

UPDATE transportation_services 
SET route_id = (SELECT id FROM service_routes WHERE route_name = 'Various-Windhoek' LIMIT 1)
WHERE name = 'Bus Transport to Windhoek';

-- Show results
SELECT 
    name,
    array_length(provider_ids, 1) as provider_count,
    provider_ids,
    prices
FROM transportation_services 
WHERE provider_ids IS NOT NULL AND array_length(provider_ids, 1) > 0
ORDER BY name;


