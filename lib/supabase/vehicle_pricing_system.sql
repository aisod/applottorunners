-- Vehicle Pricing System Update
-- This implements base and business pricing for vehicles with distance-based calculations

-- 1. Update vehicle_types table to include pricing fields
ALTER TABLE vehicle_types 
ADD COLUMN IF NOT EXISTS price_base DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS price_business DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS price_per_km DECIMAL(8, 2) DEFAULT 0.00;

-- 2. Create vehicle pricing table for more complex pricing structures
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

-- 3. Create distance-based pricing tiers for vehicles
CREATE TABLE IF NOT EXISTS vehicle_pricing_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type_id UUID REFERENCES vehicle_types(id) ON DELETE CASCADE,
  min_distance_km DECIMAL(8, 2) NOT NULL,
  max_distance_km DECIMAL(8, 2),
  base_price DECIMAL(10, 2) NOT NULL,
  business_price DECIMAL(10, 2) NOT NULL,
  price_per_km DECIMAL(8, 2) DEFAULT 0.00,
  tier_name VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vehicle_type_id, min_distance_km)
);

-- 4. Create transportation booking pricing table
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

-- 5. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_vehicle_types_pricing ON vehicle_types(price_base, price_business);
CREATE INDEX IF NOT EXISTS idx_vehicle_pricing_active ON vehicle_pricing(is_active);
CREATE INDEX IF NOT EXISTS idx_vehicle_pricing_tiers_active ON vehicle_pricing_tiers(is_active);
CREATE INDEX IF NOT EXISTS idx_transportation_booking_pricing_booking ON transportation_booking_pricing(booking_id);

-- 6. Add updated_at triggers
CREATE OR REPLACE FUNCTION update_vehicle_pricing_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_vehicle_pricing_updated_at 
BEFORE UPDATE ON vehicle_pricing 
FOR EACH ROW EXECUTE FUNCTION update_vehicle_pricing_updated_at();

-- 7. RLS Policies
ALTER TABLE vehicle_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_pricing_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transportation_booking_pricing ENABLE ROW LEVEL SECURITY;

-- Public read access for pricing (read-only data)
CREATE POLICY "Public can view active vehicle pricing" ON vehicle_pricing FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view active vehicle pricing tiers" ON vehicle_pricing_tiers FOR SELECT USING (is_active = true);

-- Users can view their own booking pricing
CREATE POLICY "Users can view their booking pricing" ON transportation_booking_pricing FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM transportation_bookings 
    WHERE transportation_bookings.id = booking_id 
    AND transportation_bookings.user_id = auth.uid()
  )
);

-- Admin policies for management
CREATE POLICY "Admins can manage vehicle pricing" ON vehicle_pricing FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage vehicle pricing tiers" ON vehicle_pricing_tiers FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can view all booking pricing" ON transportation_booking_pricing FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

-- 8. Sample data for testing
INSERT INTO vehicle_pricing (vehicle_type_id, pricing_type, base_price, business_price, price_per_km, minimum_fare, maximum_fare) 
SELECT 
  vt.id,
  'hybrid',
  vt.price_base,
  vt.price_business,
  vt.price_per_km,
  vt.price_base,
  vt.price_base * 5
FROM vehicle_types vt
WHERE vt.price_base > 0 OR vt.price_business > 0
ON CONFLICT DO NOTHING;

-- 9. Function to calculate transportation price
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

-- 10. Function to get distance between two coordinates
CREATE OR REPLACE FUNCTION calculate_distance_km(
  lat1 DECIMAL,
  lon1 DECIMAL,
  lat2 DECIMAL,
  lon2 DECIMAL
)
RETURNS DECIMAL AS $$
BEGIN
  -- Haversine formula for calculating distance between two points on Earth
  RETURN (
    6371 * acos(
      cos(radians(lat1)) * cos(radians(lat2)) * 
      cos(radians(lon2) - radians(lon1)) + 
      sin(radians(lat1)) * sin(radians(lat2))
    )
  );
END;
$$ LANGUAGE plpgsql;

-- 11. Function to create transportation booking with pricing
CREATE OR REPLACE FUNCTION create_transportation_booking_with_pricing(
  p_booking_data JSONB,
  p_pricing_data JSONB
)
RETURNS JSONB AS $$
DECLARE
  v_booking_id UUID;
  v_booking_result JSONB;
  v_pricing_result JSONB;
BEGIN
  -- Create the transportation booking
  INSERT INTO transportation_bookings (
    user_id,
    vehicle_type_id,
    pickup_location,
    dropoff_location,
    passenger_count,
    booking_date,
    booking_time,
    special_requests,
    estimated_price,
    final_price,
    status,
    payment_status
  ) VALUES (
    (p_booking_data->>'user_id')::UUID,
    (p_booking_data->>'vehicle_type_id')::UUID,
    p_booking_data->>'pickup_location',
    p_booking_data->>'dropoff_location',
    (p_booking_data->>'passenger_count')::INTEGER,
    (p_booking_data->>'booking_date')::DATE,
    (p_booking_data->>'booking_time')::TIME,
    p_booking_data->>'special_requests',
    (p_booking_data->>'estimated_price')::DECIMAL,
    (p_booking_data->>'final_price')::DECIMAL,
    p_booking_data->>'status',
    p_booking_data->>'payment_status'
  ) RETURNING to_jsonb(transportation_bookings.*) INTO v_booking_result;
  
  -- Get the booking ID
  v_booking_id := v_booking_result->>'id';
  
  -- Add the booking ID to pricing data
  p_pricing_data := jsonb_set(p_pricing_data, '{booking_id}', to_jsonb(v_booking_id));
  
  -- Create the pricing record
  INSERT INTO transportation_booking_pricing (
    booking_id,
    vehicle_type_id,
    base_price,
    business_price,
    distance_km,
    price_per_km,
    distance_cost,
    total_base_price,
    total_business_price,
    applied_price,
    user_type,
    pricing_breakdown
  ) VALUES (
    v_booking_id,
    (p_pricing_data->>'vehicle_type_id')::UUID,
    (p_pricing_data->>'base_price')::DECIMAL,
    (p_pricing_data->>'business_price')::DECIMAL,
    (p_pricing_data->>'distance_km')::DECIMAL,
    (p_pricing_data->>'price_per_km')::DECIMAL,
    (p_pricing_data->>'distance_cost')::DECIMAL,
    (p_pricing_data->>'total_base_price')::DECIMAL,
    (p_pricing_data->>'total_business_price')::DECIMAL,
    (p_pricing_data->>'applied_price')::DECIMAL,
    p_pricing_data->>'user_type',
    p_pricing_data->'pricing_breakdown'
  ) RETURNING to_jsonb(transportation_booking_pricing.*) INTO v_pricing_result;
  
  -- Return the combined result
  RETURN jsonb_build_object(
    'booking', v_booking_result,
    'pricing', v_pricing_result
  );
END;
$$ LANGUAGE plpgsql;

-- 12. Sample data for vehicle types with pricing
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

-- 13. Sample vehicle pricing data
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
