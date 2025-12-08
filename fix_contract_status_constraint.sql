-- Fix Contract Bookings Status Constraint
-- Update contract_bookings to use the same workflow as transportation_bookings
-- Status progression: pending → accepted → in_progress → completed

-- Drop existing status constraint on contract_bookings
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

-- Create new status constraint for contract_bookings with 'in_progress' status
ALTER TABLE contract_bookings ADD CONSTRAINT contract_bookings_status_check 
CHECK (status IN (
    'pending',      -- Initial booking status
    'accepted',     -- Driver has accepted the contract
    'in_progress',  -- Contract is active/in progress (NEW!)
    'confirmed',     -- Alternative status for compatibility
    'cancelled',    -- Contract was cancelled
    'completed',    -- Contract completed successfully
    'expired'       -- Contract expired
));

-- Show the updated constraint
SELECT 
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.conastraint_name
WHERE tc.table_name = 'contract_bookings' 
AND tc.constraint_type = 'CHECK'
AND cc.check_clause LIKE '%status%';

-- Show current contract booking statuses
SELECT DISTINCT status, COUNT(*) as count
FROM contract_bookings 
GROUP BY status 
ORDER BY status;
