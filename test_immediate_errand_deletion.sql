-- Test script to verify immediate errand auto-deletion works
-- This script creates a test errand and verifies it gets deleted after timeout

-- First, let's see if there are any existing immediate errands
SELECT 'Current immediate errands:' AS status;
SELECT id, title, status, is_immediate, created_at, runner_id 
FROM errands 
WHERE is_immediate = true 
ORDER BY created_at DESC 
LIMIT 5;

-- Create a test immediate errand (this will be automatically deleted after 30 seconds)
INSERT INTO errands (
    title,
    description,
    category,
    customer_id,
    status,
    is_immediate,
    price_amount,
    created_at,
    updated_at
) VALUES (
    'TEST: Immediate errand for auto-deletion',
    'This is a test errand that should be automatically deleted after 30 seconds',
    'other',
    (SELECT id FROM users LIMIT 1), -- Use first available user
    'posted',
    true,
    10.00,
    NOW(),
    NOW()
);

-- Get the ID of the test errand we just created
SELECT 'Test errand created with ID:' AS status;
SELECT id, title, created_at 
FROM errands 
WHERE title = 'TEST: Immediate errand for auto-deletion' 
AND is_immediate = true;

-- Wait a moment and check if it still exists
SELECT 'Waiting 35 seconds for auto-deletion...' AS status;

-- After 35 seconds, check if the test errand was deleted
SELECT 'Checking if test errand was auto-deleted:' AS status;
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCESS: Test errand was automatically deleted!'
        ELSE 'FAILED: Test errand still exists after timeout'
    END AS result
FROM errands 
WHERE title = 'TEST: Immediate errand for auto-deletion' 
AND is_immediate = true;

-- Show current immediate errands count
SELECT 'Current immediate errands count:' AS status;
SELECT COUNT(*) AS immediate_errands_count 
FROM errands 
WHERE is_immediate = true AND status = 'posted';
