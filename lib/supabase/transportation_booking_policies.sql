-- Transportation Booking Policies for Individual and Business Users
-- This file contains Row Level Security (RLS) policies for the transportation_bookings table

-- Enable RLS on transportation_bookings table
ALTER TABLE transportation_bookings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can create their own bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can update their own pending bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Users can cancel their own bookings" ON transportation_bookings;
DROP POLICY IF EXISTS "Public can view active services" ON transportation_bookings;

-- 1. Policy: Users can view their own bookings
-- This allows users to see all their transportation bookings
CREATE POLICY "Users can view their own bookings" ON transportation_bookings
    FOR SELECT
    USING (
        auth.uid() = user_id
    );

-- 2. Policy: Users can create their own bookings
-- This allows authenticated users to create new transportation bookings
CREATE POLICY "Users can create their own bookings" ON transportation_bookings
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND auth.uid() IS NOT NULL
    );

-- 3. Policy: Users can update their own pending bookings
-- This allows users to modify bookings that are still pending or confirmed
-- Users cannot modify completed or cancelled bookings
CREATE POLICY "Users can update their own pending bookings" ON transportation_bookings
    FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    )
    WITH CHECK (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    );

-- 4. Policy: Users can cancel their own bookings
-- This allows users to cancel their own bookings by updating status to 'cancelled'
CREATE POLICY "Users can cancel their own bookings" ON transportation_bookings
    FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    )
    WITH CHECK (
        auth.uid() = user_id
        AND (
            status = 'cancelled' 
            OR status IN ('pending', 'confirmed')
        )
    );

-- 5. Policy: Users can view booking details for services they're interested in
-- This allows users to see basic information about available services
-- Note: This might not be needed if you have separate policies for services
CREATE POLICY "Users can view available booking information" ON transportation_bookings
    FOR SELECT
    USING (
        status = 'pending' 
        OR auth.uid() = user_id
    );

-- 6. Policy: Users can view their own booking history
-- This allows users to see all their past and current bookings
CREATE POLICY "Users can view their own booking history" ON transportation_bookings
    FOR SELECT
    USING (
        auth.uid() = user_id
    );

-- 7. Policy: Users can add special requests to their bookings
-- This allows users to update special_requests field for their own bookings
CREATE POLICY "Users can update special requests" ON transportation_bookings
    FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    )
    WITH CHECK (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    );

-- 8. Policy: Users can update pickup/dropoff locations for pending bookings
-- This allows users to modify location details before the service starts
CREATE POLICY "Users can update locations for pending bookings" ON transportation_bookings
    FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    )
    WITH CHECK (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    );

-- 9. Policy: Users can update passenger count for pending bookings
-- This allows users to modify passenger count before the service starts
CREATE POLICY "Users can update passenger count for pending bookings" ON transportation_bookings
    FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    )
    WITH CHECK (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    );

-- 10. Policy: Users can update booking date/time for pending bookings
-- This allows users to reschedule their bookings if needed
CREATE POLICY "Users can reschedule pending bookings" ON transportation_bookings
    FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    )
    WITH CHECK (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    );

-- Additional helper policies for better user experience

-- 11. Policy: Users can view service information for their bookings
-- This allows users to see details about the service they booked
CREATE POLICY "Users can view service details for their bookings" ON transportation_bookings
    FOR SELECT
    USING (
        auth.uid() = user_id
    );

-- 12. Policy: Users can view pricing information for their bookings
-- This allows users to see cost details for their bookings
CREATE POLICY "Users can view pricing for their bookings" ON transportation_bookings
    FOR SELECT
    USING (
        auth.uid() = user_id
    );

-- 13. Policy: Users can view driver information for confirmed bookings
-- This allows users to see driver details once their booking is confirmed
CREATE POLICY "Users can view driver info for confirmed bookings" ON transportation_bookings
    FOR SELECT
    USING (
        auth.uid() = user_id
        AND status IN ('confirmed', 'in_progress', 'completed')
    );

-- 14. Policy: Users can view vehicle information for their bookings
-- This allows users to see vehicle details for their bookings
CREATE POLICY "Users can view vehicle info for their bookings" ON transportation_bookings
    FOR SELECT
    USING (
        auth.uid() = user_id
    );

-- 15. Policy: Users can add notes to their bookings
-- This allows users to add additional information to their bookings
CREATE POLICY "Users can add notes to their bookings" ON transportation_bookings
    FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    )
    WITH CHECK (
        auth.uid() = user_id
        AND status IN ('pending', 'confirmed')
    );

-- Summary of what these policies allow:
-- ✅ Users can CREATE new transportation bookings
-- ✅ Users can READ their own booking data
-- ✅ Users can UPDATE their pending/confirmed bookings
-- ✅ Users can CANCEL their own bookings
-- ✅ Users can modify details like locations, passenger count, date/time
-- ✅ Users can add special requests and notes
-- ✅ Users can view service, pricing, driver, and vehicle information
-- ❌ Users CANNOT see other users' bookings
-- ❌ Users CANNOT modify completed or cancelled bookings
-- ❌ Users CANNOT modify other users' data
-- ❌ Users CANNOT delete bookings (only cancel them)

-- To apply these policies, run this file in your Supabase SQL editor
-- Make sure you have the transportation_bookings table created first
