-- Transportation RLS Policy Fix Script
-- Run this in your Supabase SQL Editor to fix all RLS policy issues

-- 1. Drop all existing conflicting policies for transportation_bookings
DROP POLICY IF EXISTS "Users can create bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can view their bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Admins can manage all bookings" ON transportation_bookings;

-- 2. Create corrected policies for transportation_bookings
CREATE POLICY "Users can create bookings" ON transportation_bookings
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
  );

CREATE POLICY "Users can view their bookings" ON transportation_bookings
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
  );

CREATE POLICY "Users can update their pending bookings" ON transportation_bookings 
  FOR UPDATE USING (
    auth.uid() = user_id AND status = 'pending'
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
  );

-- 3. Fix all admin policies that reference non-existent user_profiles table
-- Categories
DROP POLICY IF EXISTS "Admins can manage categories" ON service_categories;
CREATE POLICY "Admins can manage categories" ON service_categories FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Subcategories  
DROP POLICY IF EXISTS "Admins can manage subcategories" ON service_subcategories;
CREATE POLICY "Admins can manage subcategories" ON service_subcategories FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Vehicle Types
DROP POLICY IF EXISTS "Admins can manage vehicle types" ON vehicle_types;
CREATE POLICY "Admins can manage vehicle types" ON vehicle_types FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Towns
DROP POLICY IF EXISTS "Admins can manage towns" ON towns;
CREATE POLICY "Admins can manage towns" ON towns FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Routes
DROP POLICY IF EXISTS "Admins can manage routes" ON routes;
CREATE POLICY "Admins can manage routes" ON routes FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Route Stops
DROP POLICY IF EXISTS "Admins can manage route stops" ON route_stops;
CREATE POLICY "Admins can manage route stops" ON route_stops FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Service Providers
DROP POLICY IF EXISTS "Admins can manage providers" ON service_providers;
CREATE POLICY "Admins can manage providers" ON service_providers FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Transportation Services
DROP POLICY IF EXISTS "Admins can manage services" ON transportation_services;
CREATE POLICY "Admins can manage services" ON transportation_services FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Service Schedules
DROP POLICY IF EXISTS "Admins can manage schedules" ON service_schedules;
CREATE POLICY "Admins can manage schedules" ON service_schedules FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Service Pricing
DROP POLICY IF EXISTS "Admins can manage pricing" ON service_pricing;
CREATE POLICY "Admins can manage pricing" ON service_pricing FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Pricing Tiers
DROP POLICY IF EXISTS "Admins can manage pricing tiers" ON pricing_tiers;
CREATE POLICY "Admins can manage pricing tiers" ON pricing_tiers FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- Service Reviews
DROP POLICY IF EXISTS "Admins can manage all reviews" ON service_reviews;
CREATE POLICY "Admins can manage all reviews" ON service_reviews FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.user_type IN ('admin')
  )
  OR auth.role() = 'service_role'
);

-- 4. Ensure authenticated users can insert their own profile
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id OR auth.role() = 'service_role');

-- 5. Ensure authenticated users can view and update their own profile  
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id OR auth.role() = 'service_role');

SELECT 'Transportation RLS policies fixed successfully!' as status;
