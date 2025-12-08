-- Check Transportation Booking Status Constraints
-- This script checks for any conflicting status constraints that might prevent acceptance

-- Check all constraints on transportation_bookings table
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'transportation_bookings'::regclass
AND contype = 'c'
ORDER BY conname;

-- Check if the status column allows 'accepted' status
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'transportation_bookings' 
AND column_name = 'status';

-- Check current status values in the table
SELECT 
    status,
    COUNT(*) as count
FROM transportation_bookings 
GROUP BY status
ORDER BY status;

