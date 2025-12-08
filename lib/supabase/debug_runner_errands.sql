-- Debug script to diagnose why runners can't see their accepted errands
-- Run this in your Supabase SQL editor to check the current state

-- 1. Check current user authentication
SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role;

-- 2. Check if there are any users with runner type
SELECT 
    id,
    email,
    full_name,
    user_type,
    is_verified
FROM users 
WHERE user_type = 'runner'
ORDER BY created_at DESC;

-- 3. Check all errands and their current status
SELECT 
    id,
    title,
    status,
    customer_id,
    runner_id,
    created_at,
    updated_at,
    accepted_at
FROM errands 
ORDER BY created_at DESC;

-- 4. Check specifically for accepted errands
SELECT 
    id,
    title,
    status,
    customer_id,
    runner_id,
    created_at,
    updated_at,
    accepted_at
FROM errands 
WHERE status = 'accepted'
ORDER BY created_at DESC;

-- 5. Check errands assigned to a specific runner (replace with actual runner ID)
-- Replace 'YOUR_RUNNER_ID_HERE' with an actual runner ID from step 2
SELECT 
    id,
    title,
    status,
    customer_id,
    runner_id,
    created_at,
    updated_at,
    accepted_at
FROM errands 
WHERE runner_id = 'YOUR_RUNNER_ID_HERE'
ORDER BY created_at DESC;

-- 6. Check RLS policies on errands table
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
WHERE tablename = 'errands';

-- 7. Test the getRunnerErrands query manually (replace with actual runner ID)
-- Replace 'YOUR_RUNNER_ID_HERE' with an actual runner ID from step 2
SELECT 
    *,
    customer:customer_id(full_name, phone)
FROM errands 
WHERE runner_id = 'YOUR_RUNNER_ID_HERE'
ORDER BY updated_at DESC;

-- 8. Check if there are any errands that should be visible to runners
SELECT 
    e.id,
    e.title,
    e.status,
    e.customer_id,
    e.runner_id,
    u.full_name as runner_name,
    u.user_type as runner_type
FROM errands e
LEFT JOIN users u ON e.runner_id = u.id
WHERE e.status IN ('accepted', 'in_progress', 'completed')
ORDER BY e.updated_at DESC;
