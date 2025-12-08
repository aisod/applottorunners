-- Fix errand status inconsistencies
-- This script fixes cases where errands have runner_id set but status is still 'posted'
-- These should be updated to 'accepted' status

-- First, let's see what inconsistencies exist
SELECT 
    id,
    title,
    status,
    runner_id,
    created_at,
    updated_at
FROM errands 
WHERE runner_id IS NOT NULL 
AND status = 'posted'
ORDER BY created_at DESC;

-- Update inconsistent errands to 'accepted' status
-- This ensures that errands assigned to runners show proper status
UPDATE errands 
SET 
    status = 'accepted',
    accepted_at = COALESCE(accepted_at, updated_at),
    updated_at = NOW()
WHERE runner_id IS NOT NULL 
AND status = 'posted';

-- Verify the fix
SELECT 
    COUNT(*) as total_errands,
    COUNT(CASE WHEN runner_id IS NOT NULL AND status = 'posted' THEN 1 END) as inconsistent_errands,
    COUNT(CASE WHEN runner_id IS NOT NULL AND status IN ('accepted', 'in_progress', 'completed') THEN 1 END) as properly_assigned_errands
FROM errands;

-- Show the corrected data
SELECT 
    id,
    title,
    status,
    runner_id,
    accepted_at,
    updated_at
FROM errands 
WHERE runner_id IS NOT NULL 
ORDER BY updated_at DESC
LIMIT 10;
