-- Supabase Storage Setup for Profile Images
-- Run this in your Supabase SQL Editor

-- Ensure the avatar_url column exists in the users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Enable Row Level Security on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can upload own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile images" ON storage.objects;

-- Policy 1: Allow users to upload their own profile images
CREATE POLICY "Users can upload own profile images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profiles' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy 2: Allow public read access to profile images
CREATE POLICY "Public can view profile images" ON storage.objects
  FOR SELECT USING (bucket_id = 'profiles');

-- Policy 3: Allow users to update their own profile images
CREATE POLICY "Users can update own profile images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profiles' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy 4: Allow users to delete their own profile images
CREATE POLICY "Users can delete own profile images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'profiles' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_avatar_url ON users(avatar_url);

-- Grant necessary permissions
GRANT SELECT ON storage.objects TO authenticated;
GRANT INSERT ON storage.objects TO authenticated;
GRANT UPDATE ON storage.objects TO authenticated;
GRANT DELETE ON storage.objects TO authenticated;

-- Show success message
SELECT 'Storage setup completed successfully!' as status; 