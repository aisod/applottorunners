-- Fix Vehicle Pricing Schema
-- This script ensures all required tables and columns exist for vehicle pricing

-- 1. First, check if vehicle_types table exists and has pricing columns
DO $$ 
BEGIN
    -- Add pricing columns to vehicle_types if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vehicle_types' AND column_name = 'price_base') THEN
        ALTER TABLE vehicle_types ADD COLUMN price_base DECIMAL(10, 2) DEFAULT 0.00;
        RAISE NOTICE 'Added price_base column to vehicle_types';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vehicle_types' AND column_name = 'price_business') THEN
        ALTER TABLE vehicle_types ADD COLUMN price_business DECIMAL(10, 2) DEFAULT 0.00;
        RAISE NOTICE 'Added price_business column to vehicle_types';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vehicle_types' AND column_name = 'price_per_km') THEN
        ALTER TABLE vehicle_types ADD COLUMN price_per_km DECIMAL(8, 2) DEFAULT 0.00;
        RAISE NOTICE 'Added price_per_km column to vehicle_types';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vehicle_types' AND column_name = 'service_subcategory_ids') THEN
        ALTER TABLE vehicle_types ADD COLUMN service_subcategory_ids UUID[] DEFAULT '{}';
        RAISE NOTICE 'Added service_subcategory_ids column to vehicle_types';
    END IF;
END $$;

-- 2. Create vehicle_pricing table if it doesn't exist
CREATE TABLE IF NOT EXISTS vehicle_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type_id UUID REFERENCES vehicle_types(id) ON DELETE CASCADE,
  pricing_type VARCHAR(20) CHECK (pricing_type IN ('fixed', 'per_km', 'tiered', 'hybrid')) DEFAULT 'hybrid',
  base_price DECIMAL(10, 2) NOT NULL,
  business_price DECIMAL(10, 2) NOT NULL,
  price_per_km DECIMAL(8, 2) DEFAULT 0.00,
  minimum_fare DECIMAL(8, 2) DEFAULT 0.00,
  maximum_fare DECIMAL(8, 2),
  weekend_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  holiday_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  peak_hour_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Add missing columns to transportation_bookings table
DO $$ 
BEGIN
    -- Add vehicle_type_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transportation_bookings' AND column_name = 'vehicle_type_id') THEN
        ALTER TABLE transportation_bookings ADD COLUMN vehicle_type_id UUID REFERENCES vehicle_types(id);
        RAISE NOTICE 'Added vehicle_type_id column to transportation_bookings';
    END IF;
    
    -- Add pickup_lat and pickup_lng columns if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transportation_bookings' AND column_name = 'pickup_lat') THEN
        ALTER TABLE transportation_bookings ADD COLUMN pickup_lat DECIMAL(10, 8);
        RAISE NOTICE 'Added pickup_lat column to transportation_bookings';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transportation_bookings' AND column_name = 'pickup_lng') THEN
        ALTER TABLE transportation_bookings ADD COLUMN pickup_lng DECIMAL(11, 8);
        RAISE NOTICE 'Added pickup_lng column to transportation_bookings';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transportation_bookings' AND column_name = 'dropoff_lat') THEN
        ALTER TABLE transportation_bookings ADD COLUMN dropoff_lat DECIMAL(10, 8);
        RAISE NOTICE 'Added dropoff_lat column to transportation_bookings';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transportation_bookings' AND column_name = 'dropoff_lng') THEN
        ALTER TABLE transportation_bookings ADD COLUMN dropoff_lng DECIMAL(11, 8);
        RAISE NOTICE 'Added dropoff_lng column to transportation_bookings';
    END IF;
END $$;

-- 4. Create transportation_booking_pricing table if it doesn't exist
CREATE TABLE IF NOT EXISTS transportation_booking_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES transportation_bookings(id) ON DELETE CASCADE,
  vehicle_type_id UUID REFERENCES vehicle_types(id),
  base_price DECIMAL(10, 2) NOT NULL,
  business_price DECIMAL(10, 2) NOT NULL,
  distance_km DECIMAL(8, 2) NOT NULL,
  price_per_km DECIMAL(8, 2) DEFAULT 0.00,
  distance_cost DECIMAL(10, 2) DEFAULT 0.00,
  total_base_price DECIMAL(10, 2) NOT NULL,
  total_business_price DECIMAL(10, 2) NOT NULL,
  applied_price DECIMAL(10, 2) NOT NULL,
  user_type VARCHAR(20) DEFAULT 'individual',
  pricing_breakdown JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Drop and recreate the calculate_transportation_price function
DROP FUNCTION IF EXISTS calculate_transportation_price(UUID, DECIMAL, VARCHAR);

CREATE OR REPLACE FUNCTION calculate_transportation_price(
  p_vehicle_type_id UUID,
  p_distance_km DECIMAL,
  p_user_type VARCHAR DEFAULT 'individual'
)
RETURNS TABLE(
  base_price DECIMAL,
  business_price DECIMAL,
  distance_cost DECIMAL,
  total_base_price DECIMAL,
  total_business_price DECIMAL,
  applied_price DECIMAL,
  price_per_km DECIMAL
) AS $$
DECLARE
  v_base_price DECIMAL;
  v_business_price DECIMAL;
  v_price_per_km DECIMAL;
  v_distance_cost DECIMAL;
  v_total_base DECIMAL;
  v_total_business DECIMAL;
  v_applied_price DECIMAL;
BEGIN
  -- Get vehicle pricing
  SELECT 
    COALESCE(vp.base_price, vt.price_base, 0),
    COALESCE(vp.business_price, vt.price_business, 0),
    COALESCE(vp.price_per_km, vt.price_per_km, 0)
  INTO v_base_price, v_business_price, v_price_per_km
  FROM vehicle_types vt
  LEFT JOIN vehicle_pricing vp ON vt.id = vp.vehicle_type_id AND vp.is_active = true
  WHERE vt.id = p_vehicle_type_id;
  
  -- Calculate distance cost
  v_distance_cost := p_distance_km * v_price_per_km;
  
  -- Calculate total prices (without pickup fee)
  v_total_base := v_base_price + v_distance_cost;
  v_total_business := v_business_price + v_distance_cost;
  
  -- Determine applied price based on user type
  IF p_user_type = 'business' THEN
    v_applied_price := v_total_business;
  ELSE
    v_applied_price := v_total_base;
  END IF;
  
  RETURN QUERY SELECT 
    v_base_price,
    v_business_price,
    v_distance_cost,
    v_total_base,
    v_total_business,
    v_applied_price,
    v_price_per_km;
END;
$$ LANGUAGE plpgsql;

-- 6. Insert sample vehicle types with pricing if they don't exist
INSERT INTO vehicle_types (name, capacity, description, features, icon, price_base, price_business, price_per_km) VALUES
  ('Sedan', 4, 'Comfortable sedan for city travel', ARRAY['AC', 'Music System'], 'sedan', 50.00, 75.00, 2.50),
  ('SUV', 6, 'Spacious SUV for group travel', ARRAY['AC', 'Music System', 'Luggage Space'], 'suv', 75.00, 100.00, 3.00),
  ('Minibus', 12, 'Minibus for larger groups', ARRAY['AC', 'Music System', 'Luggage Space'], 'minibus', 100.00, 125.00, 2.75),
  ('Motorcycle', 1, 'Fast motorcycle for single passenger', ARRAY['Helmet Provided'], 'motorcycle', 25.00, 35.00, 1.50),
  ('Bicycle', 1, 'Eco-friendly bicycle option', ARRAY['Basket'], 'bicycle', 15.00, 20.00, 1.00)
ON CONFLICT (name) DO UPDATE SET
  price_base = EXCLUDED.price_base,
  price_business = EXCLUDED.price_business,
  price_per_km = EXCLUDED.price_per_km;

-- 7. Insert sample vehicle pricing data
INSERT INTO vehicle_pricing (vehicle_type_id, pricing_type, base_price, business_price, price_per_km, minimum_fare, maximum_fare) 
SELECT 
  vt.id,
  'hybrid',
  vt.price_base,
  vt.price_business,
  vt.price_per_km,
  vt.price_base * 0.5, -- Minimum fare is 50% of base price
  vt.price_base * 5.0  -- Maximum fare is 5x base price
FROM vehicle_types vt
ON CONFLICT (vehicle_type_id) DO UPDATE SET
  base_price = EXCLUDED.base_price,
  business_price = EXCLUDED.business_price,
  price_per_km = EXCLUDED.price_per_km,
  minimum_fare = EXCLUDED.minimum_fare,
  maximum_fare = EXCLUDED.maximum_fare;

-- 8. Test the function
SELECT 'Testing calculate_transportation_price function...' as test_status;

SELECT * FROM calculate_transportation_price(
  (SELECT id FROM vehicle_types WHERE name = 'Sedan' LIMIT 1),
  10.0, -- 10 km distance
  'individual' -- user type
);

SELECT 'Schema fix completed successfully!' as completion_status;
