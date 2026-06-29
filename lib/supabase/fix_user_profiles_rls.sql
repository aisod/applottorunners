-- ======================================================
-- Run this in your Supabase SQL Editor
-- This creates a function that bypasses RLS to get user profiles
-- ======================================================

-- Drop if exists
DROP FUNCTION IF EXISTS get_user_profiles(UUID[]);

-- Create a SECURITY DEFINER function (runs as postgres, bypasses RLS)
CREATE OR REPLACE FUNCTION get_user_profiles(user_ids UUID[])
RETURNS TABLE(id UUID, full_name TEXT, phone TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, full_name, phone 
  FROM users 
  WHERE id = ANY(user_ids);
$$;

-- Grant execute permission to authenticated and anonymous users
GRANT EXECUTE ON FUNCTION get_user_profiles(UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_profiles(UUID[]) TO anon;

-- Also ensure the open SELECT policy exists on users table
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
CREATE POLICY "Users can view all profiles" ON users
    FOR SELECT USING (true);

SELECT 'get_user_profiles function created successfully!' AS status;
