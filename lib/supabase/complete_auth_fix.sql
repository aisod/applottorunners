-- Complete Authentication Fix Script
-- Run this in your Supabase SQL Editor to fix all authentication issues

-- 1. Create function to handle new user sign-ups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert user profile with default values
  -- The user_type will be updated by the app after sign-up
  INSERT INTO public.users (id, email, full_name, user_type, is_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'individual'),
    false
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
    user_type = COALESCE(EXCLUDED.user_type, public.users.user_type),
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create trigger on auth.users to run after INSERT
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.users TO anon, authenticated;

-- 4. Update RLS policies to ensure proper access
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id OR auth.role() = 'service_role');

-- 5. Fix any existing users without profiles
-- This will create profiles for any auth users that don't have them
INSERT INTO public.users (id, email, full_name, user_type, is_verified)
SELECT 
    auth_users.id,
    auth_users.email,
    COALESCE(auth_users.raw_user_meta_data->>'full_name', auth_users.email),
    COALESCE(auth_users.raw_user_meta_data->>'user_type', 'individual'),
    false
FROM auth.users auth_users
LEFT JOIN public.users ON auth_users.id = public.users.id
WHERE public.users.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 6. Update storage policies for better access
CREATE POLICY "Service role can manage all storage" ON storage.objects
    FOR ALL USING (auth.role() = 'service_role');

-- 7. Fix RLS policy for transportation_bookings to allow authenticated users to create bookings
DROP POLICY IF EXISTS "Users can create bookings" ON transportation_bookings;
CREATE POLICY "Users can create bookings" ON transportation_bookings
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
  );

-- 8. Ensure users can view their own bookings
DROP POLICY IF EXISTS "Users can view their bookings" ON transportation_bookings;
CREATE POLICY "Users can view their bookings" ON transportation_bookings
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
  );

SELECT 'Authentication fix completed successfully!' as status;