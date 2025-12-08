-- COMPREHENSIVE STORAGE POLICY FIX
-- This script will completely reset and fix all storage policies
-- Run this in your Supabase SQL Editor

-- ============================================================================
-- STEP 1: DROP ALL EXISTING POLICIES TO AVOID CONFLICTS
-- ============================================================================

-- Drop ALL existing policies for storage.objects to start fresh
DROP POLICY IF EXISTS "Anyone can view errand images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view errand images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload errand images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own errand images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own errand images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all errand images" ON storage.objects;

DROP POLICY IF EXISTS "Anyone can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;

DROP POLICY IF EXISTS "Only users can view their verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own verification docs" ON storage.objects;

-- ============================================================================
-- STEP 2: CREATE CLEAN POLICIES FOR ERRAND-IMAGES BUCKET
-- ============================================================================

-- Policy 1: Public read access to errand images
CREATE POLICY "Public can view errand images" ON storage.objects
    FOR SELECT USING (bucket_id = 'errand-images');

-- Policy 2: Authenticated users can upload to errand images
CREATE POLICY "Authenticated users can upload errand images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );

-- Policy 3: Users can update their own errand images
CREATE POLICY "Users can update their own errand images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 4: Users can delete their own errand images
CREATE POLICY "Users can delete their own errand images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 5: Admins can manage all errand images
CREATE POLICY "Admins can manage all errand images" ON storage.objects
    FOR ALL USING (
        bucket_id = 'errand-images' AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- ============================================================================
-- STEP 3: CREATE CLEAN POLICIES FOR PROFILES BUCKET
-- ============================================================================

-- Policy 1: Public read access to profile images
CREATE POLICY "Public can view profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

-- Policy 2: Authenticated users can upload profile images
CREATE POLICY "Authenticated users can upload profile images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profiles' AND 
        auth.role() = 'authenticated'
    );

-- Policy 3: Users can update their own profile images
CREATE POLICY "Users can update their own profile images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profiles' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 4: Users can delete their own profile images
CREATE POLICY "Users can delete their own profile images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profiles' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- STEP 4: CREATE CLEAN POLICIES FOR VERIFICATION-DOCS BUCKET
-- ============================================================================

-- Policy 1: Users can view their own verification docs
CREATE POLICY "Users can view their own verification docs" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'verification-docs' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 2: Authenticated users can upload verification docs
CREATE POLICY "Authenticated users can upload verification docs" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'verification-docs' AND 
        auth.role() = 'authenticated'
    );

-- Policy 3: Users can update their own verification docs
CREATE POLICY "Users can update their own verification docs" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'verification-docs' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 4: Users can delete their own verification docs
CREATE POLICY "Users can delete their own verification docs" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'verification-docs' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 5: Admins can manage all verification docs
CREATE POLICY "Admins can manage all verification docs" ON storage.objects
    FOR ALL USING (
        bucket_id = 'verification-docs' AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- ============================================================================
-- STEP 5: ENSURE ALL BUCKETS EXIST AND ARE PROPERLY CONFIGURED
-- ============================================================================

-- Ensure errand-images bucket exists and is public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'errand-images', 
    'errand-images', 
    true, 
    52428800, -- 50MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf'];

-- Ensure profiles bucket exists and is public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profiles', 
    'profiles', 
    true, 
    10485760, -- 10MB limit for profile images
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Ensure verification-docs bucket exists and is private
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verification-docs', 
    'verification-docs', 
    false, -- Private bucket
    52428800, -- 50MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf'];

-- ============================================================================
-- STEP 6: VERIFICATION QUERIES
-- ============================================================================

-- Show all created policies
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN qual IS NOT NULL THEN 'Has USING clause'
        ELSE 'No USING clause'
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
        ELSE 'No WITH CHECK clause'
    END as with_check_clause
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;

-- Show bucket configurations
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
ORDER BY id;

-- Show success message
SELECT 'All storage policies have been reset and recreated successfully!' as status;
