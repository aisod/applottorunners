-- Fix Transportation Booking Acceptance Issue
-- This script fixes the RLS policies that prevent runners from accepting transportation bookings

-- First, drop all existing conflicting policies for transportation_bookings
DROP POLICY IF EXISTS "Users can view their bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can create bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can update their pending bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can cancel their own bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Drivers can view assigned bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Drivers can update assigned bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Drivers can update bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Drivers can accept bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Runners can view available bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Admins can manage all bookings" ON transportation_bookings;

-- Create comprehensive policies for transportation_bookings

-- 1. SELECT Policy - Allow users to view relevant bookings
CREATE POLICY "Users can view relevant bookings" ON transportation_bookings 
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

-- 2. INSERT Policy - Allow users to create their own bookings
CREATE POLICY "Users can create bookings" ON transportation_bookings 
FOR INSERT WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
);

-- 3. UPDATE Policy - Allow users and drivers to update bookings appropriately
CREATE POLICY "Users and drivers can update bookings" ON transportation_bookings 
FOR UPDATE USING (
    -- Users can update their own pending bookings
    (auth.uid() = user_id AND status = 'pending')
    -- Drivers can update bookings they are assigned to
    OR auth.uid() = driver_id
    -- Anyone can accept available bookings (assign themselves as driver)
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
    -- Users can only update their own bookings to certain statuses
    (auth.uid() = user_id AND status IN ('pending', 'cancelled'))
    -- Drivers can update bookings they are assigned to
    OR auth.uid() = driver_id
    -- Allow accepting bookings (setting driver_id and status to 'accepted')
    OR (driver_id IS NOT NULL AND status IN ('accepted', 'in_progress', 'completed', 'cancelled'))
    -- Admins can do anything
    OR EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type IN ('admin')
    )
    -- Service role can do anything
    OR auth.role() = 'service_role'
);

-- 4. DELETE Policy - Only allow admins and service role to delete
CREATE POLICY "Only admins can delete bookings" ON transportation_bookings 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
);

-- Test the policies by checking if they exist
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'transportation_bookings' 
ORDER BY policyname;

-- Verify the fix
SELECT 'Transportation booking acceptance policies updated successfully!' as status;

