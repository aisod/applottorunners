-- SIMPLIFIED STORAGE POLICY FIX
-- This version uses simpler policies that don't rely on complex path checking
-- Run this in your Supabase SQL Editor

-- ============================================================================
-- STEP 1: DROP ALL EXISTING POLICIES
-- ============================================================================

-- Drop ALL existing policies for storage.objects
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
DROP POLICY IF EXISTS "Users can view their own verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own verification docs" ON storage.objects;

-- ============================================================================
-- STEP 2: CREATE SIMPLIFIED POLICIES (NO COMPLEX PATH CHECKING)
-- ============================================================================

-- ERRAND-IMAGES BUCKET POLICIES
-- Policy 1: Anyone can view errand images (public read)
CREATE POLICY "Anyone can view errand images" ON storage.objects
    FOR SELECT USING (bucket_id = 'errand-images');

-- Policy 2: Any authenticated user can upload to errand images
CREATE POLICY "Any authenticated user can upload errand images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );

-- Policy 3: Any authenticated user can update errand images
CREATE POLICY "Any authenticated user can update errand images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );

-- Policy 4: Any authenticated user can delete errand images
CREATE POLICY "Any authenticated user can delete errand images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );

-- PROFILES BUCKET POLICIES
-- Policy 1: Anyone can view profile images (public read)
CREATE POLICY "Anyone can view profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

-- Policy 2: Any authenticated user can upload profile images
CREATE POLICY "Any authenticated user can upload profile images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profiles' AND 
        auth.role() = 'authenticated'
    );

-- Policy 3: Any authenticated user can update profile images
CREATE POLICY "Any authenticated user can update profile images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profiles' AND 
        auth.role() = 'authenticated'
    );

-- Policy 4: Any authenticated user can delete profile images
CREATE POLICY "Any authenticated user can delete profile images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profiles' AND 
        auth.role() = 'authenticated'
    );

-- VERIFICATION-DOCS BUCKET POLICIES
-- Policy 1: Any authenticated user can view verification docs
CREATE POLICY "Any authenticated user can view verification docs" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'verification-docs' AND 
        auth.role() = 'authenticated'
    );

-- Policy 2: Any authenticated user can upload verification docs
CREATE POLICY "Any authenticated user can upload verification docs" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'verification-docs' AND 
        auth.role() = 'authenticated'
    );

-- Policy 3: Any authenticated user can update verification docs
CREATE POLICY "Any authenticated user can update verification docs" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'verification-docs' AND 
        auth.role() = 'authenticated'
    );

-- Policy 4: Any authenticated user can delete verification docs
CREATE POLICY "Any authenticated user can delete verification docs" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'verification-docs' AND 
        auth.role() = 'authenticated'
    );

-- ============================================================================
-- STEP 3: ENSURE BUCKETS EXIST
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
    10485760, -- 10MB limit
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
-- STEP 4: VERIFICATION
-- ============================================================================

-- Show all created policies
SELECT 
    policyname,
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
SELECT 'Simplified storage policies created successfully! Upload should now work.' as status;
