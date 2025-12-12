-- Transportation System Tables for Lotto Runners
-- This includes dynamic categories, e-hailing services, routes, schedules, and pricing

-- 1. Service Categories (Dynamic)
CREATE TABLE service_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(7), -- Hex color code
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Service Subcategories
CREATE TABLE service_subcategories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(name)
);

-- 3. Vehicle Types
CREATE TABLE vehicle_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL UNIQUE,
  capacity INTEGER NOT NULL,
  description TEXT,
  features TEXT[], -- Array of features like "AC", "WiFi", "Luggage"
  icon VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Towns/Cities
CREATE TABLE towns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  region VARCHAR(50),
  country VARCHAR(50) DEFAULT 'Namibia',
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Routes
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  origin_town_id UUID REFERENCES towns(id),
  destination_town_id UUID REFERENCES towns(id),
  distance_km DECIMAL(8, 2),
  estimated_duration_minutes INTEGER,
  route_type VARCHAR(20) CHECK (route_type IN ('intercity', 'local', 'airport', 'shuttle')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(origin_town_id, destination_town_id, route_type)
);

-- 6. Route Stops (for multi-stop routes)
CREATE TABLE route_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  town_id UUID REFERENCES towns(id),
  stop_order INTEGER NOT NULL,
  arrival_offset_minutes INTEGER DEFAULT 0, -- Minutes from start
  departure_offset_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(route_id, stop_order),
  UNIQUE(route_id, town_id)
);

-- 7. Service Providers (Bus companies, shuttle services, etc.)
CREATE TABLE service_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  contact_phone VARCHAR(20),
  contact_email VARCHAR(100),
  license_number VARCHAR(50),
  rating DECIMAL(3, 2) DEFAULT 0.00,
  total_reviews INTEGER DEFAULT 0,
  is_verified BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Transportation Services
CREATE TABLE transportation_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subcategory_id UUID REFERENCES service_subcategories(id),
  provider_id UUID REFERENCES service_providers(id),
  vehicle_type_id UUID REFERENCES vehicle_types(id),
  route_id UUID REFERENCES routes(id),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  features TEXT[],
  operating_days INTEGER[] DEFAULT '{1,2,3,4,5,6,7}', -- 1=Monday, 7=Sunday
  is_home_pickup BOOLEAN DEFAULT false,
  pickup_radius_km DECIMAL(5, 2),
  advance_booking_hours INTEGER DEFAULT 1,
  cancellation_hours INTEGER DEFAULT 2,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Service Pricing
CREATE TABLE service_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID REFERENCES transportation_services(id) ON DELETE CASCADE,
  pricing_type VARCHAR(20) CHECK (pricing_type IN ('fixed', 'per_km', 'per_hour', 'tiered')),
  base_price DECIMAL(10, 2) NOT NULL,
  price_per_km DECIMAL(8, 2),
  price_per_hour DECIMAL(8, 2),
  pickup_fee DECIMAL(8, 2) DEFAULT 0.00,
  weekend_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  holiday_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  peak_hour_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  peak_hours TIME[][2], -- Array of time ranges
  minimum_fare DECIMAL(8, 2),
  maximum_fare DECIMAL(8, 2),
  currency VARCHAR(3) DEFAULT 'NAD',
  effective_from DATE DEFAULT CURRENT_DATE,
  effective_until DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. Distance-based Pricing Tiers
CREATE TABLE pricing_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID REFERENCES transportation_services(id) ON DELETE CASCADE,
  min_distance_km DECIMAL(8, 2) NOT NULL,
  max_distance_km DECIMAL(8, 2),
  price DECIMAL(10, 2) NOT NULL,
  tier_name VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(service_id, min_distance_km)
);

-- 12. Bookings (Enhanced from existing errands)
CREATE TABLE transportation_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  service_id UUID REFERENCES transportation_services(id),
  pickup_location TEXT,
  pickup_coordinates POINT,
  dropoff_location TEXT,
  dropoff_coordinates POINT,
  passenger_count INTEGER DEFAULT 1,
  booking_date DATE NOT NULL,
  booking_time TIME NOT NULL,
  special_requests TEXT,
  estimated_price DECIMAL(10, 2),
  final_price DECIMAL(10, 2),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')),
  payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
  driver_id UUID REFERENCES users(id),
  vehicle_registration VARCHAR(20),
  booking_reference VARCHAR(20) UNIQUE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. Reviews and Ratings
CREATE TABLE service_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES transportation_bookings(id),
  user_id UUID REFERENCES users(id),
  service_id UUID REFERENCES transportation_services(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  driver_rating INTEGER CHECK (driver_rating >= 1 AND driver_rating <= 5),
  vehicle_rating INTEGER CHECK (vehicle_rating >= 1 AND vehicle_rating <= 5),
  punctuality_rating INTEGER CHECK (punctuality_rating >= 1 AND punctuality_rating <= 5),
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(booking_id, user_id)
);

-- Add indexes for performance
CREATE INDEX idx_service_categories_active ON service_categories(is_active, sort_order);
CREATE INDEX idx_service_subcategories_active ON service_subcategories(is_active);
CREATE INDEX idx_routes_towns ON routes(origin_town_id, destination_town_id);
CREATE INDEX idx_transportation_services_subcategory ON transportation_services(subcategory_id, is_active);
CREATE INDEX idx_service_pricing_service ON service_pricing(service_id, is_active);
CREATE INDEX idx_transportation_bookings_user ON transportation_bookings(user_id, status);
CREATE INDEX idx_transportation_bookings_service ON transportation_bookings(service_id, booking_date);

-- Add updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_service_categories_updated_at BEFORE UPDATE ON service_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_subcategories_updated_at BEFORE UPDATE ON service_subcategories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehicle_types_updated_at BEFORE UPDATE ON vehicle_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_towns_updated_at BEFORE UPDATE ON towns FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_providers_updated_at BEFORE UPDATE ON service_providers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transportation_services_updated_at BEFORE UPDATE ON transportation_services FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_pricing_updated_at BEFORE UPDATE ON service_pricing FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transportation_bookings_updated_at BEFORE UPDATE ON transportation_bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE towns ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transportation_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transportation_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_reviews ENABLE ROW LEVEL SECURITY;

-- Public read access for categories, vehicle types, towns, routes (read-only data)
CREATE POLICY "Public can view active categories" ON service_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view active subcategories" ON service_subcategories FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view active vehicle types" ON vehicle_types FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view active towns" ON towns FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view active routes" ON routes FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view route stops" ON route_stops FOR SELECT USING (true);
CREATE POLICY "Public can view active providers" ON service_providers FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view active services" ON transportation_services FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view active pricing" ON service_pricing FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view pricing tiers" ON pricing_tiers FOR SELECT USING (true);

-- Admin policies for management
CREATE POLICY "Admins can manage categories" ON service_categories FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage subcategories" ON service_subcategories FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage vehicle types" ON vehicle_types FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage towns" ON towns FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage routes" ON routes FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage route stops" ON route_stops FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage providers" ON service_providers FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage services" ON transportation_services FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);


CREATE POLICY "Admins can manage pricing" ON service_pricing FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage pricing tiers" ON pricing_tiers FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

-- Booking policies
CREATE POLICY "Users can view their bookings" ON transportation_bookings FOR SELECT USING (
  auth.uid() = user_id
);

CREATE POLICY "Users can create bookings" ON transportation_bookings FOR INSERT WITH CHECK (
  auth.uid() = user_id
);

CREATE POLICY "Users can update their pending bookings" ON transportation_bookings FOR UPDATE USING (
  auth.uid() = user_id AND status = 'pending'
);

CREATE POLICY "Drivers can view assigned bookings" ON transportation_bookings FOR SELECT USING (
  auth.uid() = driver_id
);

CREATE POLICY "Drivers can update assigned bookings" ON transportation_bookings FOR UPDATE USING (
  auth.uid() = driver_id
) WITH CHECK (
  auth.uid() = driver_id
);

CREATE POLICY "Admins can view all bookings" ON transportation_bookings FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

CREATE POLICY "Admins can manage all bookings" ON transportation_bookings FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
);

-- Review policies
CREATE POLICY "Public can view verified reviews" ON service_reviews FOR SELECT USING (is_verified = true);

CREATE POLICY "Users can create reviews for their bookings" ON service_reviews FOR INSERT WITH CHECK (
  auth.uid() = user_id AND
  EXISTS (
    SELECT 1 FROM transportation_bookings 
    WHERE transportation_bookings.id = booking_id 
    AND transportation_bookings.user_id = auth.uid()
    AND transportation_bookings.status = 'completed'
  )
);

CREATE POLICY "Users can view their reviews" ON service_reviews FOR SELECT USING (
  auth.uid() = user_id
);

CREATE POLICY "Users can update their unverified reviews" ON service_reviews FOR UPDATE USING (
  auth.uid() = user_id AND is_verified = false
);

CREATE POLICY "Admins can manage all reviews" ON service_reviews FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
); 