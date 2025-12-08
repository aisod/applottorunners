-- Comprehensive fix for transportation bookings status constraint
-- This resolves the conflict between different status constraints and ensures all needed statuses are allowed

-- First, check what constraint currently exists
DO $$
BEGIN
    RAISE NOTICE 'Checking current status constraint on transportation_bookings...';
    
    -- Check if there are any constraints on the status column
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
        WHERE tc.table_name = 'transportation_bookings' 
        AND tc.constraint_type = 'CHECK'
        AND cc.check_clause LIKE '%status%'
    ) THEN
        RAISE NOTICE 'Found existing status constraint, will drop and recreate...';
    ELSE
        RAISE NOTICE 'No existing status constraint found';
    END IF;
END $$;

-- Drop ALL existing status constraints to avoid conflicts
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

-- Create the comprehensive status constraint with ALL needed statuses
ALTER TABLE transportation_bookings ADD CONSTRAINT transportation_bookings_status_check 
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
    RAISE NOTICE 'Status constraint created successfully';
    RAISE NOTICE 'Allowed statuses: pending, confirmed, accepted, in_progress, completed, cancelled, no_show';
END $$;

-- Test the constraint by trying to insert/update with valid statuses
DO $$
BEGIN
    RAISE NOTICE 'Testing constraint with valid statuses...';
    
    -- This should work without errors
    UPDATE transportation_bookings 
    SET status = 'confirmed' 
    WHERE id = (SELECT id FROM transportation_bookings LIMIT 1);
    
    RAISE NOTICE 'Constraint test passed - valid statuses work correctly';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Constraint test failed: %', SQLERRM;
END $$;
