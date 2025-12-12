-- Transportation Related Table Policies for Individual and Business Users
-- This file contains RLS policies for tables related to transportation bookings

-- ====================================================================
-- SERVICE_SUBCATEGORIES TABLE POLICIES
-- ====================================================================

-- Enable RLS on service_subcategories table
ALTER TABLE service_subcategories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view active subcategories" ON service_subcategories;
DROP POLICY IF EXISTS "Admins can manage subcategories" ON service_subcategories;

-- Policy: Public can view active subcategories
-- This allows all users (including guests) to see available service types
CREATE POLICY "Public can view active subcategories" ON service_subcategories
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can manage all subcategories
-- This allows administrators to create, update, and delete subcategories
CREATE POLICY "Admins can manage subcategories" ON service_subcategories
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================
-- TRANSPORTATION_SERVICES TABLE POLICIES
-- ====================================================================

-- Enable RLS on transportation_services table
ALTER TABLE transportation_services ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view active services" ON transportation_services;
DROP POLICY IF EXISTS "Admins can manage services" ON transportation_services;

-- Policy: Public can view active services
-- This allows all users to see available transportation services
CREATE POLICY "Public can view active services" ON transportation_services
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can manage all services
-- This allows administrators to create, update, and delete services
CREATE POLICY "Admins can manage services" ON transportation_services
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================
-- VEHICLE_TYPES TABLE POLICIES
-- ====================================================================

-- Enable RLS on vehicle_types table
ALTER TABLE vehicle_types ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view active vehicle types" ON vehicle_types;
DROP POLICY IF EXISTS "Admins can manage vehicle types" ON vehicle_types;

-- Policy: Public can view active vehicle types
-- This allows all users to see available vehicle types
CREATE POLICY "Public can view active vehicle types" ON vehicle_types
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can manage all vehicle types
-- This allows administrators to create, update, and delete vehicle types
CREATE POLICY "Admins can manage vehicle types" ON vehicle_types
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================
-- SERVICE_PROVIDERS TABLE POLICIES
-- ====================================================================

-- Enable RLS on service_providers table
ALTER TABLE service_providers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view active providers" ON service_providers;
DROP POLICY IF EXISTS "Admins can manage providers" ON service_providers;

-- Policy: Public can view active service providers
-- This allows all users to see available service providers
CREATE POLICY "Public can view active providers" ON service_providers
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can manage all service providers
-- This allows administrators to create, update, and delete providers
CREATE POLICY "Admins can manage providers" ON service_providers
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================
-- TOWNS TABLE POLICIES
-- ====================================================================

-- Enable RLS on towns table
ALTER TABLE towns ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view active towns" ON towns;
DROP POLICY IF EXISTS "Admins can manage towns" ON towns;

-- Policy: Public can view active towns
-- This allows all users to see available towns/cities
CREATE POLICY "Public can view active towns" ON towns
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can manage all towns
-- This allows administrators to create, update, and delete towns
CREATE POLICY "Admins can manage towns" ON towns
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================
-- ROUTES TABLE POLICIES
-- ====================================================================

-- Enable RLS on routes table
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view active routes" ON routes;
DROP POLICY IF EXISTS "Admins can manage routes" ON routes;

-- Policy: Public can view active routes
-- This allows all users to see available routes
CREATE POLICY "Public can view active routes" ON routes
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can manage all routes
-- This allows administrators to create, update, and delete routes
CREATE POLICY "Admins can manage routes" ON routes
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================

-- ====================================================================
-- SERVICE_PRICING TABLE POLICIES
-- ====================================================================

-- Enable RLS on service_pricing table
ALTER TABLE service_pricing ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view active pricing" ON service_pricing;
DROP POLICY IF EXISTS "Admins can manage pricing" ON service_pricing;

-- Policy: Public can view active service pricing
-- This allows all users to see pricing information
CREATE POLICY "Public can view active pricing" ON service_pricing
    FOR SELECT
    USING (is_active = true);

-- Policy: Admins can manage all pricing
-- This allows administrators to create, update, and delete pricing
CREATE POLICY "Admins can manage pricing" ON service_pricing
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================
-- PRICING_TIERS TABLE POLICIES
-- ====================================================================

-- Enable RLS on pricing_tiers table
ALTER TABLE pricing_tiers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view pricing tiers" ON pricing_tiers;
DROP POLICY IF EXISTS "Admins can manage pricing tiers" ON pricing_tiers;

-- Policy: Public can view pricing tiers
-- This allows all users to see pricing tier information
CREATE POLICY "Public can view pricing tiers" ON pricing_tiers
    FOR SELECT
    USING (true);

-- Policy: Admins can manage all pricing tiers
-- This allows administrators to create, update, and delete pricing tiers
CREATE POLICY "Admins can manage pricing tiers" ON pricing_tiers
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type IN ('admin', 'super_admin')
        )
    );

-- ====================================================================
-- SUMMARY OF POLICIES
-- ====================================================================

-- What these policies allow for Individual and Business Users:

-- ✅ READ ACCESS:
--   - View all active service subcategories
--   - View all active transportation services
--   - View all active vehicle types
--   - View all active service providers
--   - View all active towns/cities
--   - View all active routes
--   - View all active service schedules
--   - View all active pricing information
--   - View pricing tiers

-- ✅ WRITE ACCESS:
--   - Create transportation bookings (via transportation_bookings table)
--   - Update their own bookings
--   - Cancel their own bookings

-- ❌ NO ACCESS:
--   - Cannot create/modify service definitions
--   - Cannot create/modify vehicle types
--   - Cannot create/modify providers
--   - Cannot create/modify routes or schedules
--   - Cannot modify pricing
--   - Cannot see other users' data

-- To apply these policies:
-- 1. Run this file in your Supabase SQL editor
-- 2. Make sure all the tables exist first
-- 3. Verify that RLS is enabled on all tables
-- 4. Test the policies with different user types
