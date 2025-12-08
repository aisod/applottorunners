-- ====================================================================
-- SERVICE_PROVIDERS TABLE POLICIES
-- ====================================================================
-- This file creates comprehensive Row Level Security policies for the service_providers table
-- Run this in your Supabase SQL Editor after creating the service_providers table

-- First, ensure RLS is enabled on the service_providers table
ALTER TABLE service_providers ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public can view active providers" ON service_providers;
DROP POLICY IF EXISTS "Admins can manage providers" ON service_providers;
DROP POLICY IF EXISTS "Admins can manage all providers" ON service_providers;

-- ============================================================================
-- HELPER FUNCTION FOR ADMIN CHECK (if not already exists)
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
-- PUBLIC ACCESS POLICIES
-- ============================================================================

-- Public can view active service providers (for browsing services)
CREATE POLICY "Public can view active providers" ON service_providers 
FOR SELECT USING (is_active = true);

-- ============================================================================
-- ADMIN ACCESS POLICIES
-- ============================================================================

-- Admins can perform all operations on service providers
CREATE POLICY "Admins can manage all providers" ON service_providers 
FOR ALL USING (is_admin());

-- ============================================================================
-- SERVICE PROVIDER OWNER POLICIES (if you want providers to manage their own data)
-- ============================================================================

-- Service providers can view their own data (if you add an owner_id field later)
-- CREATE POLICY "Providers can view own data" ON service_providers 
-- FOR SELECT USING (owner_id = auth.uid());

-- Service providers can update their own data (if you add an owner_id field later)
-- CREATE POLICY "Providers can update own data" ON service_providers 
-- FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());

-- ============================================================================
-- VERIFICATION POLICIES
-- ============================================================================

-- Verified providers can be viewed by everyone (this is already covered by the public policy)
-- The is_active = true condition ensures only active providers are visible

-- ============================================================================
-- TESTING THE POLICIES
-- ============================================================================

-- You can test the policies with these queries (run as admin user):

-- Test public access (should only see active providers)
-- SELECT * FROM service_providers WHERE is_active = true;

-- Test admin access (should see all providers)
-- SELECT * FROM service_providers;

-- Test admin insert
-- INSERT INTO service_providers (name, description, contact_phone, contact_email, rating, is_active) 
-- VALUES ('Test Provider', 'Test Description', '+1234567890', 'test@example.com', 4.5, true);

-- Test admin update
-- UPDATE service_providers SET rating = 5.0 WHERE name = 'Test Provider';

-- Test admin delete
-- DELETE FROM service_providers WHERE name = 'Test Provider';

-- ============================================================================
-- POLICY VERIFICATION
-- ============================================================================

-- Check if policies are properly created
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
-- FROM pg_policies 
-- WHERE tablename = 'service_providers'
-- ORDER BY policyname;

-- Check if RLS is enabled
-- SELECT schemaname, tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE tablename = 'service_providers';
