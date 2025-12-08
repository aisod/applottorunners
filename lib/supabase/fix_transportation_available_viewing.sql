-- Fix for transportation bookings viewing - allow runners to see available bookings
-- This adds the missing policy that allows viewing of unassigned transportation bookings

-- Drop existing conflicting policies first
DROP POLICY IF EXISTS "Runners can view available bookings" ON transportation_bookings;

-- Create policy that allows anyone to view available (unassigned) transportation bookings
-- This is similar to the errands policy "Anyone can view posted errands"
CREATE POLICY "Runners can view available bookings" ON transportation_bookings 
FOR SELECT USING (
    -- Allow viewing if the booking is pending and has no driver assigned
    (status = 'pending' AND driver_id IS NULL)
    OR
    -- Or if the user is the customer who made the booking
    auth.uid() = user_id
    OR
    -- Or if the user is the assigned driver
    auth.uid() = driver_id
    OR
    -- Or if the user is an admin
    is_admin()
);

-- Create policy that allows drivers to accept transportation bookings
-- This allows updating the driver_id and status when accepting a booking
CREATE POLICY "Drivers can accept bookings" ON transportation_bookings 
FOR UPDATE USING (
    -- Allow if the user is the assigned driver
    auth.uid() = driver_id
    OR
    -- Or if the user is an admin
    is_admin()
    OR
    -- Allow initial acceptance (when driver_id is being set from NULL)
    (OLD.driver_id IS NULL AND driver_id IS NOT NULL)
) WITH CHECK (
    -- Ensure only specific fields can be updated when accepting
    -- This prevents unauthorized modifications
    (
        -- Allow updating driver_id when accepting a booking
        (driver_id IS NOT NULL AND OLD.driver_id IS NULL)
        OR
                 -- Allow updating status when driver is assigned (including 'accepted')
         (driver_id IS NOT NULL AND OLD.driver_id IS NULL AND status IN ('accepted', 'in_progress'))
        OR
        -- Allow updating other fields if already assigned to this driver
        (OLD.driver_id = auth.uid())
        OR
        -- Allow admin updates
        is_admin()
    )
);

-- Remove the test field from transportation_bookings table if it exists
-- This cleans up any test data that might have been added
DO $$
BEGIN
    -- Check if the test field exists and remove it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transportation_bookings' 
        AND column_name = 'test_field'
    ) THEN
        ALTER TABLE transportation_bookings DROP COLUMN test_field;
        RAISE NOTICE 'Removed test_field column from transportation_bookings';
    ELSE
        RAISE NOTICE 'test_field column does not exist in transportation_bookings';
    END IF;
END $$;

-- Verify all policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'transportation_bookings' 
AND policyname IN ('Runners can view available bookings', 'Drivers can accept bookings')
ORDER BY policyname;
