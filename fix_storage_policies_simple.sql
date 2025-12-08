-- Supabase-Compatible Storage Policy Fix
-- Run this in your Supabase SQL Editor
-- 
-- This version avoids permission issues by only creating policies
-- without trying to modify table structure or grant permissions

-- ============================================================================
-- CLEAN UP EXISTING POLICIES
-- ============================================================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view errand images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view errand images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload errand images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own errand images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own errand images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all errand images" ON storage.objects;

-- ============================================================================
-- CREATE NEW POLICIES
-- ============================================================================

-- Policy 1: Allow public read access to errand images
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
-- ENSURE BUCKET EXISTS
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
-- VERIFICATION
-- ============================================================================

-- Show created policies
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
AND policyname LIKE '%errand%'
ORDER BY policyname;

-- Show bucket configuration
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'errand-images';

-- Show success message
SELECT 'Storage policies for errand-images bucket have been created successfully!' as status;
