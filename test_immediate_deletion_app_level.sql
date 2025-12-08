-- Test script to verify app-level immediate errand deletion
-- This simulates what the Flutter app will do

-- First, let's see current immediate errands
SELECT 'Current immediate errands:' AS status;
SELECT id, title, status, is_immediate, created_at, runner_id 
FROM errands 
WHERE is_immediate = true 
ORDER BY created_at DESC;

-- Create a test immediate errand that should be deleted
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
    'TEST: App-level deletion test',
    'This errand should be deleted by app-level cleanup',
    'other',
    (SELECT id FROM users LIMIT 1),
    'posted',
    true,
    15.00,
    NOW() - INTERVAL '35 seconds', -- Make it 35 seconds old (expired)
    NOW() - INTERVAL '35 seconds'
);

-- Show the test errand we just created
SELECT 'Test errand created:' AS status;
SELECT id, title, created_at, 
       EXTRACT(EPOCH FROM (NOW() - created_at)) AS age_seconds
FROM errands 
WHERE title = 'TEST: App-level deletion test';

-- Simulate the app-level cleanup (this is what the Flutter app will do)
SELECT 'Simulating app-level cleanup...' AS status;

-- This is the exact query the Flutter app will run
DELETE FROM errands 
WHERE status = 'posted' 
AND is_immediate = true 
AND runner_id IS NULL
AND created_at < NOW() - INTERVAL '30 seconds';

-- Check if the test errand was deleted
SELECT 'Checking if test errand was deleted:' AS status;
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCESS: Test errand was deleted!'
        ELSE 'FAILED: Test errand still exists'
    END AS result
FROM errands 
WHERE title = 'TEST: App-level deletion test';

-- Show remaining immediate errands
SELECT 'Remaining immediate errands:' AS status;
SELECT id, title, status, is_immediate, created_at, runner_id 
FROM errands 
WHERE is_immediate = true 
ORDER BY created_at DESC;
