-- Fix Storage Policies for Runner Application Documents
-- Run this in your Supabase SQL Editor to fix the RLS policy issues
-- 
-- NOTE: This script uses Supabase-compatible commands that work with
-- the default permissions structure

-- ============================================================================
-- STORAGE POLICY FIX FOR ERRAND-IMAGES BUCKET
-- ============================================================================

-- Note: We don't need to alter storage.objects as RLS is already enabled
-- and we don't have ownership permissions to modify the table structure

-- Drop all existing conflicting policies for errand-images bucket
DROP POLICY IF EXISTS "Anyone can view errand images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload errand images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own errand images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own errand images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all errand images" ON storage.objects;

-- Create comprehensive policies for errand-images bucket
-- Policy 1: Allow anyone to view errand images (public read access)
CREATE POLICY "Public can view errand images" ON storage.objects
    FOR SELECT USING (bucket_id = 'errand-images');

-- Policy 2: Allow authenticated users to upload errand images
CREATE POLICY "Authenticated users can upload errand images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'errand-images' AND 
        auth.role() = 'authenticated'
    );

-- Policy 3: Allow users to update their own errand images
CREATE POLICY "Users can update their own errand images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 4: Allow users to delete their own errand images
CREATE POLICY "Users can delete their own errand images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'errand-images' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy 5: Allow admins to manage all errand images
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
-- VERIFY BUCKET EXISTS AND IS PUBLIC
-- ============================================================================

-- Ensure the errand-images bucket exists and is public
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

-- ============================================================================
-- PERMISSIONS NOTE
-- ============================================================================

-- Note: GRANT statements are not needed as Supabase handles these permissions
-- automatically through the RLS policies. The policies themselves provide
-- the necessary access control without requiring explicit GRANT statements.

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Query to verify policies are in place
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%errand%'
ORDER BY policyname;

-- Query to verify bucket configuration
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'errand-images';

-- Query to test current user permissions
SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role,
    u.user_type,
    u.full_name
FROM users u 
WHERE u.id = auth.uid();

-- Show success message
SELECT 'Storage policies for errand-images bucket have been fixed successfully!' as status;
