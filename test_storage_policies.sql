-- QUICK STORAGE POLICY TEST
-- Run this in your Supabase SQL Editor to test the current policies

-- Test 1: Check if policies exist
SELECT 
    policyname,
    cmd,
    bucket_id
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%errand%'
ORDER BY policyname;

-- Test 2: Check bucket configuration
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'errand-images';

-- Test 3: Check current user authentication
SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role,
    u.user_type,
    u.full_name
FROM users u 
WHERE u.id = auth.uid();

-- Test 4: Test policy evaluation (this will show if policies are working)
-- Note: This might show an error if not authenticated, which is expected
SELECT 
    bucket_id,
    name,
    CASE 
        WHEN bucket_id = 'errand-images' THEN 'errand-images bucket'
        WHEN bucket_id = 'profiles' THEN 'profiles bucket'
        WHEN bucket_id = 'verification-docs' THEN 'verification-docs bucket'
        ELSE 'other bucket'
    END as bucket_type
FROM storage.objects 
LIMIT 5;
