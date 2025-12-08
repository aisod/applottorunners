-- Fix Admin Policies for Errands and Bus Bookings
-- This script ensures admins can properly accept and manage errands and bus bookings

-- First, let's ensure RLS is enabled on all relevant tables
ALTER TABLE errands ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_service_bookings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Admins can view all errands" ON errands;
DROP POLICY IF EXISTS "Admins can create errands" ON errands;
DROP POLICY IF EXISTS "Admins can update any errand" ON errands;
DROP POLICY IF EXISTS "Admins can delete any errand" ON errands;

DROP POLICY IF EXISTS "Admins can manage all bus service bookings" ON bus_service_bookings;

-- Create comprehensive errands policies for admins
CREATE POLICY "Admins can view all errands" ON errands
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

CREATE POLICY "Admins can create errands" ON errands
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

CREATE POLICY "Admins can update any errand" ON errands
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

CREATE POLICY "Admins can delete any errand" ON errands
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- Create comprehensive bus service bookings policies for admins
CREATE POLICY "Admins can view all bus service bookings" ON bus_service_bookings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

CREATE POLICY "Admins can create bus service bookings" ON bus_service_bookings
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

CREATE POLICY "Admins can update any bus service booking" ON bus_service_bookings
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

CREATE POLICY "Admins can delete any bus service booking" ON bus_service_bookings
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- Verify the policies were created
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
WHERE tablename IN ('errands', 'bus_service_bookings')
AND policyname LIKE '%Admin%'
ORDER BY tablename, policyname;
