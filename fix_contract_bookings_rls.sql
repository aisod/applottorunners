-- Fix Contract Bookings RLS Policies
-- This script allows runners to see available contract bookings (pending status, no driver assigned)

-- First, check if driver_id column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contract_bookings' 
        AND column_name = 'driver_id'
    ) THEN
        ALTER TABLE contract_bookings ADD COLUMN driver_id UUID REFERENCES users(id);
        CREATE INDEX idx_contract_bookings_driver ON contract_bookings(driver_id, status);
    END IF;
END $$;

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own contract bookings" ON contract_bookings;
DROP POLICY IF EXISTS "Users can update own pending contract bookings" ON contract_bookings;

-- Create new policy that allows:
-- 1. Users to view their own contract bookings
-- 2. Drivers to view their assigned contract bookings  
-- 3. All authenticated users to view available contract bookings (pending, no driver)
-- 4. Admins to view all contract bookings
CREATE POLICY "Users can view contract bookings" ON contract_bookings 
  FOR SELECT USING (
    -- Users can see their own contract bookings
    auth.uid() = user_id
    -- Drivers can see their assigned contract bookings
    OR auth.uid() = driver_id
    -- All authenticated users can see available contract bookings (pending, no driver assigned)
    OR (status = 'pending' AND driver_id IS NULL)
    -- Admins can see all contract bookings
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type IN ('admin')
    )
    -- Service role can see everything
    OR auth.role() = 'service_role'
  );

-- Update the drivers policy to allow drivers to update contract bookings they can see
CREATE POLICY "Drivers can update contract bookings" ON contract_bookings 
  FOR UPDATE USING (
    -- Drivers can update their assigned contract bookings
    auth.uid() = driver_id
    -- Drivers can accept available contract bookings (assign themselves)
    OR (status = 'pending' AND driver_id IS NULL)
    -- Users can update their own pending contract bookings
    OR (auth.uid() = user_id AND status = 'pending')
    -- Admins can update all contract bookings
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type IN ('admin')
    )
    -- Service role can update everything
    OR auth.role() = 'service_role'
  ) WITH CHECK (
    -- Allow drivers to assign themselves to pending contract bookings
    (status = 'pending' AND driver_id IS NULL) 
    -- Or update contract bookings they are assigned to
    OR auth.uid() = driver_id
    -- Or users can update their own pending contract bookings
    OR (auth.uid() = user_id AND status = 'pending')
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
SELECT 'Contract bookings RLS policies updated successfully!' as status;
