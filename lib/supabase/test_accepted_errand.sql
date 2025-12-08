-- Test script to create a sample accepted errand for testing
-- This will help verify if the issue is with data or permissions

-- First, let's check if we have any users to work with
SELECT 
    id,
    email,
    full_name,
    user_type
FROM users 
WHERE user_type IN ('runner', 'individual')
LIMIT 5;

-- Insert a test errand that's accepted by a runner
-- Replace the UUIDs with actual user IDs from the query above
INSERT INTO errands (
    customer_id,
    runner_id,
    title,
    description,
    category,
    price_amount,
    time_limit_hours,
    status,
    location_address,
    created_at,
    updated_at,
    accepted_at
) VALUES (
    -- Replace with actual customer ID (individual user)
    'CUSTOMER_UUID_HERE',
    -- Replace with actual runner ID
    'RUNNER_UUID_HERE',
    'Test Accepted Errand',
    'This is a test errand that has been accepted by a runner',
    'other',
    25.00,
    24,
    'accepted',
    '123 Test Street, Test City',
    NOW(),
    NOW(),
    NOW()
);

-- Verify the errand was created
SELECT 
    id,
    title,
    status,
    customer_id,
    runner_id,
    created_at,
    accepted_at
FROM errands 
WHERE title = 'Test Accepted Errand';

-- Test the getRunnerErrands query manually
-- Replace RUNNER_UUID_HERE with the actual runner ID
SELECT 
    *,
    customer:customer_id(full_name, phone)
FROM errands 
WHERE runner_id = 'RUNNER_UUID_HERE'
ORDER BY updated_at DESC;
