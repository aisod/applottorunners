-- Simplified Admin Policies for Lotto Runners Application
-- This file creates comprehensive policies that allow admin users to read and write data
-- on all tables in the system using a helper function.

-- ============================================================================
-- HELPER FUNCTION FOR ADMIN CHECK
-- ============================================================================

-- Create a helper function to check if current user is admin
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
-- CORE TABLES ADMIN POLICIES (USING HELPER FUNCTION)
-- ============================================================================

-- Users table admin policies
CREATE POLICY "Admins can view all users" ON users FOR SELECT USING (is_admin());
CREATE POLICY "Admins can create users" ON users FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "Admins can update any user" ON users FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete any user" ON users FOR DELETE USING (is_admin());

-- Errands table admin policies
CREATE POLICY "Admins can view all errands" ON errands FOR SELECT USING (is_admin());
CREATE POLICY "Admins can create errands" ON errands FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "Admins can update any errand" ON errands FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete any errand" ON errands FOR DELETE USING (is_admin());

-- Runner applications table admin policies
CREATE POLICY "Admins can view all runner applications" ON runner_applications FOR SELECT USING (is_admin());
CREATE POLICY "Admins can create runner applications" ON runner_applications FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "Admins can update any runner application" ON runner_applications FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete any runner application" ON runner_applications FOR DELETE USING (is_admin());

-- Errand updates table admin policies
CREATE POLICY "Admins can view all errand updates" ON errand_updates FOR SELECT USING (is_admin());
CREATE POLICY "Admins can create errand updates" ON errand_updates FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "Admins can update any errand update" ON errand_updates FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete any errand update" ON errand_updates FOR DELETE USING (is_admin());

-- Reviews table admin policies
CREATE POLICY "Admins can view all reviews" ON reviews FOR SELECT USING (is_admin());
CREATE POLICY "Admins can create reviews" ON reviews FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "Admins can update any review" ON reviews FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete any review" ON reviews FOR DELETE USING (is_admin());

-- Payments table admin policies
CREATE POLICY "Admins can view all payments" ON payments FOR SELECT USING (is_admin());
CREATE POLICY "Admins can create payments" ON payments FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "Admins can update any payment" ON payments FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete any payment" ON payments FOR DELETE USING (is_admin());

-- ============================================================================
-- TRANSPORTATION TABLES ADMIN POLICIES (USING HELPER FUNCTION)
-- ============================================================================

-- Service categories admin policies (comprehensive access)
CREATE POLICY "Admins can manage all categories" ON service_categories FOR ALL USING (is_admin());

-- Service subcategories admin policies
CREATE POLICY "Admins can manage all subcategories" ON service_subcategories FOR ALL USING (is_admin());

-- Vehicle types admin policies
CREATE POLICY "Admins can manage all vehicle types" ON vehicle_types FOR ALL USING (is_admin());

-- Towns admin policies
CREATE POLICY "Admins can manage all towns" ON towns FOR ALL USING (is_admin());

-- Routes admin policies
CREATE POLICY "Admins can manage all routes" ON routes FOR ALL USING (is_admin());

-- Route stops admin policies
CREATE POLICY "Admins can manage all route stops" ON route_stops FOR ALL USING (is_admin());

-- Service providers admin policies
CREATE POLICY "Admins can manage all providers" ON service_providers FOR ALL USING (is_admin());

-- Transportation services admin policies
CREATE POLICY "Admins can manage all services" ON transportation_services FOR ALL USING (is_admin());


-- Service pricing admin policies
CREATE POLICY "Admins can manage all pricing" ON service_pricing FOR ALL USING (is_admin());

-- Pricing tiers admin policies
CREATE POLICY "Admins can manage all pricing tiers" ON pricing_tiers FOR ALL USING (is_admin());

-- Transportation bookings admin policies
CREATE POLICY "Admins can manage all bookings" ON transportation_bookings FOR ALL USING (is_admin());

-- Service reviews admin policies
CREATE POLICY "Admins can manage all service reviews" ON service_reviews FOR ALL USING (is_admin());

-- ============================================================================
-- STORAGE ADMIN POLICIES (USING HELPER FUNCTION)
-- ============================================================================

-- Admin access to all storage buckets
CREATE POLICY "Admins can manage all errand images" ON storage.objects
    FOR ALL USING (bucket_id = 'errand-images' AND is_admin());

CREATE POLICY "Admins can manage all profile images" ON storage.objects
    FOR ALL USING (bucket_id = 'profiles' AND is_admin());

CREATE POLICY "Admins can manage all verification docs" ON storage.objects
    FOR ALL USING (bucket_id = 'verification-docs' AND is_admin());

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Query to verify admin policies are in place
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE policyname LIKE '%admin%' OR policyname LIKE '%Admin%'
ORDER BY tablename, policyname;

-- Query to show all tables with RLS enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- Query to test the is_admin function
SELECT 
    auth.uid() as current_user_id,
    is_admin() as is_admin_user,
    u.user_type,
    u.full_name
FROM users u 
WHERE u.id = auth.uid();
