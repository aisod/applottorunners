-- ====================================================================
-- COMPLETE TRANSPORTATION SYSTEM POLICIES
-- ====================================================================
-- This file creates comprehensive Row Level Security policies for all transportation tables
-- Run this in your Supabase SQL Editor after creating all transportation tables

-- ============================================================================
-- HELPER FUNCTION FOR ADMIN CHECK
-- ============================================================================

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SERVICE_PROVIDERS TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE service_providers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active providers" ON service_providers;
DROP POLICY IF EXISTS "Admins can manage providers" ON service_providers;
DROP POLICY IF EXISTS "Admins can manage all providers" ON service_providers;

-- Create new policies
CREATE POLICY "Public can view active providers" ON service_providers 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all providers" ON service_providers 
FOR ALL USING (is_admin());

-- ============================================================================
-- TRANSPORTATION_SERVICES TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE transportation_services ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active services" ON transportation_services;
DROP POLICY IF EXISTS "Admins can manage services" ON transportation_services;
DROP POLICY IF EXISTS "Admins can manage all services" ON transportation_services;

-- Create new policies
CREATE POLICY "Public can view active services" ON transportation_services 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all services" ON transportation_services 
FOR ALL USING (is_admin());

-- ============================================================================
-- SERVICE_CATEGORIES TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active categories" ON service_categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON service_categories;
DROP POLICY IF EXISTS "Admins can manage all categories" ON service_categories;

-- Create new policies
CREATE POLICY "Public can view active categories" ON service_categories 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all categories" ON service_categories 
FOR ALL USING (is_admin());

-- ============================================================================
-- SERVICE_SUBCATEGORIES TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE service_subcategories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active subcategories" ON service_subcategories;
DROP POLICY IF EXISTS "Admins can manage subcategories" ON service_subcategories;
DROP POLICY IF EXISTS "Admins can manage all subcategories" ON service_subcategories;

-- Create new policies
CREATE POLICY "Public can view active subcategories" ON service_subcategories 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all subcategories" ON service_subcategories 
FOR ALL USING (is_admin());

-- ============================================================================
-- VEHICLE_TYPES TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE vehicle_types ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active vehicle types" ON vehicle_types;
DROP POLICY IF EXISTS "Admins can manage vehicle types" ON vehicle_types;
DROP POLICY IF EXISTS "Admins can manage all vehicle types" ON vehicle_types;

-- Create new policies
CREATE POLICY "Public can view active vehicle types" ON vehicle_types 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all vehicle types" ON vehicle_types 
FOR ALL USING (is_admin());

-- ============================================================================
-- TOWNS TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE towns ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active towns" ON towns;
DROP POLICY IF EXISTS "Admins can manage towns" ON towns;
DROP POLICY IF EXISTS "Admins can manage all towns" ON towns;

-- Create new policies
CREATE POLICY "Public can view active towns" ON towns 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all towns" ON towns 
FOR ALL USING (is_admin());

-- ============================================================================
-- ROUTES TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active routes" ON routes;
DROP POLICY IF EXISTS "Admins can manage routes" ON routes;
DROP POLICY IF EXISTS "Admins can manage all routes" ON routes;

-- Create new policies
CREATE POLICY "Public can view active routes" ON routes 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all routes" ON routes 
FOR ALL USING (is_admin());

-- ============================================================================
-- ROUTE_STOPS TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view route stops" ON route_stops;
DROP POLICY IF EXISTS "Admins can manage route stops" ON route_stops;
DROP POLICY IF EXISTS "Admins can manage all route stops" ON route_stops;

-- Create new policies
CREATE POLICY "Public can view route stops" ON route_stops 
FOR SELECT USING (true);

CREATE POLICY "Admins can manage all route stops" ON route_stops 
FOR ALL USING (is_admin());

-- ============================================================================

-- ============================================================================
-- SERVICE_PRICING TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE service_pricing ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view active pricing" ON service_pricing;
DROP POLICY IF EXISTS "Admins can manage pricing" ON service_pricing;
DROP POLICY IF EXISTS "Admins can manage all pricing" ON service_pricing;

-- Create new policies
CREATE POLICY "Public can view active pricing" ON service_pricing 
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all pricing" ON service_pricing 
FOR ALL USING (is_admin());

-- ============================================================================
-- PRICING_TIERS TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE pricing_tiers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view pricing tiers" ON pricing_tiers;
DROP POLICY IF EXISTS "Admins can manage pricing tiers" ON pricing_tiers;
DROP POLICY IF EXISTS "Admins can manage all pricing tiers" ON pricing_tiers;

-- Create new policies
CREATE POLICY "Public can view pricing tiers" ON pricing_tiers 
FOR SELECT USING (true);

CREATE POLICY "Admins can manage all pricing tiers" ON pricing_tiers 
FOR ALL USING (is_admin());

-- ============================================================================
-- TRANSPORTATION_BOOKINGS TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE transportation_bookings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can create bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can update their pending bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Drivers can view assigned bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Drivers can update assigned bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Admins can manage all bookings" ON transportation_bookings;

-- Create new policies
-- Users can view their own bookings
CREATE POLICY "Users can view their bookings" ON transportation_bookings 
FOR SELECT USING (auth.uid() = user_id);

-- Users can create bookings
CREATE POLICY "Users can create bookings" ON transportation_bookings 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their pending bookings
CREATE POLICY "Users can update their pending bookings" ON transportation_bookings 
FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Drivers can view assigned bookings
CREATE POLICY "Drivers can view assigned bookings" ON transportation_bookings 
FOR SELECT USING (auth.uid() = driver_id);

-- Drivers can update assigned bookings
CREATE POLICY "Drivers can update assigned bookings" ON transportation_bookings 
FOR UPDATE USING (auth.uid() = driver_id) WITH CHECK (auth.uid() = driver_id);

-- Admins can view all bookings
CREATE POLICY "Admins can view all bookings" ON transportation_bookings 
FOR SELECT USING (is_admin());

-- Admins can manage all bookings
CREATE POLICY "Admins can manage all bookings" ON transportation_bookings 
FOR ALL USING (is_admin());

-- ============================================================================
-- SERVICE_REVIEWS TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE service_reviews ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view verified reviews" ON service_reviews;
DROP POLICY IF EXISTS "Users can create reviews for their bookings" ON service_reviews;
DROP POLICY IF EXISTS "Users can view their reviews" ON service_reviews;
DROP POLICY IF EXISTS "Users can update their unverified reviews" ON service_reviews;
DROP POLICY IF EXISTS "Admins can manage all reviews" ON service_reviews;

-- Create new policies
-- Public can view verified reviews
CREATE POLICY "Public can view verified reviews" ON service_reviews 
FOR SELECT USING (is_verified = true);

-- Users can create reviews for their completed bookings
CREATE POLICY "Users can create reviews for their bookings" ON service_reviews 
FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
        SELECT 1 FROM transportation_bookings 
        WHERE transportation_bookings.id = booking_id 
        AND transportation_bookings.user_id = auth.uid()
        AND transportation_bookings.status = 'completed'
    )
);

-- Users can view their own reviews
CREATE POLICY "Users can view their reviews" ON service_reviews 
FOR SELECT USING (auth.uid() = user_id);

-- Users can update their unverified reviews
CREATE POLICY "Users can update their unverified reviews" ON service_reviews 
FOR UPDATE USING (auth.uid() = user_id AND is_verified = false);

-- Admins can manage all reviews
CREATE POLICY "Admins can manage all reviews" ON service_reviews 
FOR ALL USING (is_admin());

-- ============================================================================
-- POLICY VERIFICATION
-- ============================================================================

-- Check if all policies are properly created
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
-- FROM pg_policies 
-- WHERE tablename IN (
--     'service_providers', 'transportation_services', 'service_categories', 
--     'service_subcategories', 'vehicle_types', 'towns', 'routes', 'route_stops',
--     'service_pricing', 'pricing_tiers', 
--     'transportation_bookings', 'service_reviews'
-- )
-- ORDER BY tablename, policyname;

-- Check if RLS is enabled on all tables
-- SELECT schemaname, tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE tablename IN (
--     'service_providers', 'transportation_services', 'service_categories', 
--     'service_subcategories', 'vehicle_types', 'towns', 'routes', 'route_stops',
--     'service_pricing', 'pricing_tiers', 
--     'transportation_bookings', 'service_reviews'
-- )
-- ORDER BY tablename;
