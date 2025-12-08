-- Complete Fix for Transportation Booking Acceptance Issues
-- This script resolves all issues preventing runners from accepting contract and shuttle services

-- ==============================================
-- 1. FIX TRANSPORTATION_BOOKINGS STATUS CONSTRAINT
-- ==============================================

-- Drop existing conflicting status constraints
DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Find and drop all check constraints that reference the status column
    FOR constraint_name IN 
        SELECT tc.constraint_name 
        FROM information_schema.table_constraints tc
        JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
        WHERE tc.table_name = 'transportation_bookings' 
        AND tc.constraint_type = 'CHECK'
        AND cc.check_clause LIKE '%status%'
    LOOP
        EXECUTE 'ALTER TABLE transportation_bookings DROP CONSTRAINT IF EXISTS ' || quote_ident(constraint_name);
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END LOOP;
END $$;

-- Create comprehensive status constraint with ALL needed statuses
ALTER TABLE transportation_bookings ADD CONSTRAINT transportation_bookings_status_check 
CHECK (status IN (
    'pending',      -- Initial booking status
    'accepted',     -- Driver has accepted the booking (THIS WAS MISSING!)
    'confirmed',     -- Alternative status for compatibility
    'in_progress',  -- Driver is en route or picking up
    'completed',    -- Trip completed successfully
    'cancelled',    -- Booking was cancelled
    'no_show'       -- Customer didn't show up
));

-- ==============================================
-- 2. FIX CONTRACT_BOOKINGS TABLE STRUCTURE
-- ==============================================

-- Add driver_id column to contract_bookings if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'contract_bookings' 
        AND column_name = 'driver_id'
    ) THEN
        ALTER TABLE contract_bookings ADD COLUMN driver_id UUID REFERENCES users(id);
        CREATE INDEX idx_contract_bookings_driver ON contract_bookings(driver_id, status);
        RAISE NOTICE 'Added driver_id column to contract_bookings';
    ELSE
        RAISE NOTICE 'driver_id column already exists in contract_bookings';
    END IF;
END $$;

-- Update contract_bookings status constraint to include 'accepted'
DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Find and drop existing status constraint
    FOR constraint_name IN 
        SELECT tc.constraint_name 
        FROM information_schema.table_constraints tc
        JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
        WHERE tc.table_name = 'contract_bookings' 
        AND tc.constraint_type = 'CHECK'
        AND cc.check_clause LIKE '%status%'
    LOOP
        EXECUTE 'ALTER TABLE contract_bookings DROP CONSTRAINT IF EXISTS ' || quote_ident(constraint_name);
        RAISE NOTICE 'Dropped contract_bookings constraint: %', constraint_name;
    END LOOP;
END $$;

-- Create new status constraint for contract_bookings with 'accepted' status
ALTER TABLE contract_bookings ADD CONSTRAINT contract_bookings_status_check 
CHECK (status IN (
    'pending',      -- Initial booking status
    'accepted',     -- Driver has accepted the contract (NEW!)
    'confirmed',     -- Alternative status for compatibility
    'active',       -- Contract is active
    'cancelled',    -- Contract was cancelled
    'completed',    -- Contract completed successfully
    'expired'       -- Contract expired
));

-- ==============================================
-- 3. FIX RLS POLICIES FOR TRANSPORTATION_BOOKINGS
-- ==============================================

-- Drop existing restrictive policies
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
    OR (driver_id IS NOT NULL AND status IN ('accepted', 'confirmed', 'in_progress', 'completed', 'cancelled'))
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

-- ==============================================
-- 4. FIX RLS POLICIES FOR CONTRACT_BOOKINGS
-- ==============================================

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own contract bookings" ON contract_bookings;
DROP POLICY IF EXISTS "Users can insert own contract bookings" ON contract_bookings;
DROP POLICY IF EXISTS "Users can update own pending contract bookings" ON contract_bookings;
DROP POLICY IF EXISTS "Admins can manage all contract bookings" ON contract_bookings;

-- Create new comprehensive policies for contract_bookings

-- 1. SELECT Policy - Allow users to view relevant contract bookings
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

-- 2. INSERT Policy - Allow users to create their own contract bookings
CREATE POLICY "Users can create contract bookings" ON contract_bookings 
FOR INSERT WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
);

-- 3. UPDATE Policy - Allow users and drivers to update contract bookings appropriately
CREATE POLICY "Users and drivers can update contract bookings" ON contract_bookings 
FOR UPDATE USING (
    -- Users can update their own pending contract bookings
    (auth.uid() = user_id AND status = 'pending')
    -- Drivers can update bookings they are assigned to
    OR auth.uid() = driver_id
    -- Anyone can accept available contract bookings (assign themselves as driver)
    OR (status = 'pending' AND driver_id IS NULL)
    -- Admins can update all contract bookings
    OR EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type IN ('admin')
    )
    -- Service role can update everything
    OR auth.role() = 'service_role'
) WITH CHECK (
    -- Users can only update their own contract bookings to certain statuses
    (auth.uid() = user_id AND status IN ('pending', 'cancelled'))
    -- Drivers can update contract bookings they are assigned to
    OR auth.uid() = driver_id
    -- Allow accepting contract bookings (setting driver_id and status to 'accepted')
    OR (driver_id IS NOT NULL AND status IN ('accepted', 'confirmed', 'active', 'completed', 'cancelled', 'expired'))
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
CREATE POLICY "Only admins can delete contract bookings" ON contract_bookings 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type IN ('admin')
    )
    OR auth.role() = 'service_role'
);

-- ==============================================
-- 5. VERIFICATION AND TESTING
-- ==============================================

-- Test the constraints by checking if they exist
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
WHERE tablename IN ('transportation_bookings', 'contract_bookings')
ORDER BY tablename, policyname;

-- Verify the constraints were created
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid IN ('transportation_bookings'::regclass, 'contract_bookings'::regclass)
AND contype = 'c'
ORDER BY conname;

-- Final success message
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'TRANSPORTATION ACCEPTANCE FIX COMPLETED!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Fixed Issues:';
    RAISE NOTICE '1. Added "accepted" status to transportation_bookings constraint';
    RAISE NOTICE '2. Added driver_id column to contract_bookings table';
    RAISE NOTICE '3. Added "accepted" status to contract_bookings constraint';
    RAISE NOTICE '4. Updated RLS policies to allow runner acceptance';
    RAISE NOTICE '5. Runners can now accept both shuttle and contract services';
    RAISE NOTICE '==============================================';
END $$;
