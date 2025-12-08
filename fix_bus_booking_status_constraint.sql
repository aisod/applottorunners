-- Fix Bus Booking Status Constraint to Match Transportation Orders
-- This updates the bus_service_bookings table to use the same status values as transportation_bookings

-- First, drop the existing constraint
ALTER TABLE bus_service_bookings DROP CONSTRAINT IF EXISTS bus_service_bookings_status_check;

-- Create the new constraint with status values that match transportation_bookings
ALTER TABLE bus_service_bookings ADD CONSTRAINT bus_service_bookings_status_check 
CHECK (status IN (
    'pending',      -- Initial booking status
    'accepted',     -- Driver has accepted the booking
    'in_progress',  -- Driver is en route or picking up
    'completed',    -- Trip completed successfully
    'cancelled',    -- Booking was cancelled
    'no_show'       -- Customer didn't show up
));

-- Verify the constraint was created
DO $$
BEGIN
    RAISE NOTICE 'Bus booking status constraint updated successfully';
    RAISE NOTICE 'Allowed statuses: pending, accepted, in_progress, completed, cancelled, no_show';
END $$;
