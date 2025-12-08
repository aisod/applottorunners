-- Add 'pending_price' status to errands table constraint
-- This fixes the PostgrestException when creating special orders
-- Error: "new row for relation "errands" violates check constraint "errands_status_check""

-- First, drop the existing status constraint
ALTER TABLE errands DROP CONSTRAINT IF EXISTS errands_status_check;

-- Add the new constraint with 'pending_price' and 'price_quoted' included
ALTER TABLE errands ADD CONSTRAINT errands_status_check 
CHECK (status IN (
    'posted',           -- Regular posted errands
    'accepted',         -- Accepted by a runner
    'in_progress',      -- Currently being worked on
    'pending',          -- Pending acceptance (for immediate requests)
    'pending_price',    -- NEW: Pending price quotation (for special orders)
    'price_quoted',     -- NEW: Price has been quoted, awaiting customer approval
    'completed',        -- Successfully completed
    'cancelled'         -- Cancelled by customer or runner
));

-- Add comment to document the constraint
COMMENT ON CONSTRAINT errands_status_check ON errands IS 
'Updated to include pending_price and price_quoted statuses for special orders workflow';

-- Verify the constraint was created correctly
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'errands'::regclass 
AND conname = 'errands_status_check';

-- Check current status values in use
SELECT DISTINCT status, COUNT(*) as count
FROM errands
GROUP BY status
ORDER BY count DESC;

