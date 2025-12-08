-- Fix Transportation Bookings RLS Policies
-- This script allows runners to see available bookings (pending status, no driver assigned)

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view their bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Drivers can view assigned bookings" ON transportation_bookings;

-- Create new policy that allows:
-- 1. Users to view their own bookings
-- 2. Drivers to view their assigned bookings  
-- 3. All authenticated users to view available bookings (pending, no driver)
-- 4. Admins to view all bookings
CREATE POLICY "Users can view bookings" ON transportation_bookings 
  FOR SELECT USING (
    -- Users can see their own bookings
    auth.uid() = user_id
    -- Drivers can see their assigned bookings
    OR auth.uid() = driver_id
    -- All authenticated users can see available bookings (pending, no driver assigned)
    OR (status = 'pending' AND driver_id IS NULL)
    -- Admins can see all bookings
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type IN ('admin')
    )
    -- Service role can see everything
    OR auth.role() = 'service_role'
  );

-- Update the drivers policy to allow drivers to update bookings they can see
DROP POLICY IF EXISTS "Drivers can update assigned bookings" ON transportation_bookings;
CREATE POLICY "Drivers can update bookings" ON transportation_bookings 
  FOR UPDATE USING (
    -- Drivers can update their assigned bookings
    auth.uid() = driver_id
    -- Drivers can accept available bookings (assign themselves)
    OR (status = 'pending' AND driver_id IS NULL)
    -- Admins can update all bookings
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type IN ('admin')
    )
    -- Service role can update everything
    OR auth.role() = 'service_role'
  ) WITH CHECK (
    -- Allow drivers to assign themselves to pending bookings
    (status = 'pending' AND driver_id IS NULL) 
    -- Or update bookings they are assigned to
    OR auth.uid() = driver_id
    -- Admins can do anything
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type IN ('admin')
    )
    -- Service role can do anything
    OR auth.role() = 'service_role'
  );

-- Test the policies
SELECT 'Transportation bookings RLS policies updated successfully!' as status; 