-- Diagnostic script to identify verification issues
-- Run this to check the current state and identify problems

-- 1. Check if RPC functions exist
SELECT 
    routine_name, 
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('update_user_verification', 'update_runner_application_status')
ORDER BY routine_name;

-- 2. Check current user authentication (run as admin)
SELECT 
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN 'No authenticated user'
        ELSE 'User authenticated'
    END as auth_status;

-- 3. Check if current user is admin
SELECT 
    u.id,
    u.full_name,
    u.user_type,
    u.is_verified,
    CASE 
        WHEN u.user_type = 'admin' THEN 'Admin user'
        ELSE 'Non-admin user'
    END as admin_status
FROM users u
WHERE u.id = auth.uid();

-- 4. Check target user (replace with actual user ID from error)
SELECT 
    u.id,
    u.full_name,
    u.email,
    u.user_type,
    u.is_verified,
    u.created_at,
    u.updated_at
FROM users u
WHERE u.id = 'f4299e49-a923-4619-8117-c3e1cdfd08f3'; -- Replace with actual user ID

-- 5. Check RLS policies on users table
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
WHERE tablename = 'users'
ORDER BY policyname;

-- 6. Test RPC function directly (replace with actual user ID)
SELECT update_user_verification(
    'f4299e49-a923-4619-8117-c3e1cdfd08f3'::uuid, -- Replace with actual user ID
    true
) as rpc_result;

-- 7. Check if user has runner applications
SELECT 
    ra.id as application_id,
    ra.user_id,
    ra.verification_status,
    ra.has_vehicle,
    ra.vehicle_type,
    ra.applied_at,
    ra.reviewed_at,
    ra.reviewed_by
FROM runner_applications ra
WHERE ra.user_id = 'f4299e49-a923-4619-8117-c3e1cdfd08f3'; -- Replace with actual user ID

-- 8. Check recent verification attempts (if you have a logs table)
-- This would help identify patterns in failed attempts

-- 9. Test direct update (this should fail if RLS is blocking)
UPDATE users 
SET 
    is_verified = true,
    updated_at = NOW()
WHERE id = 'f4299e49-a923-4619-8117-c3e1cdfd08f3' -- Replace with actual user ID
RETURNING id, full_name, is_verified, updated_at;
