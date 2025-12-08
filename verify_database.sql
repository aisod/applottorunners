-- Verification Script for Lotto Runners Database
-- Run this in Supabase SQL Editor to check your setup

-- 1. Check if users table exists
SELECT 'Checking users table...' as status;
SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE user_type = 'admin') as admin_users,
    COUNT(*) FILTER (WHERE user_type = 'customer') as customer_users,
    COUNT(*) FILTER (WHERE user_type = 'runner') as runner_users,
    COUNT(*) FILTER (WHERE user_type = 'individual') as individual_users,
    COUNT(*) FILTER (WHERE user_type = 'business') as business_users
FROM users;

-- 2. Check test accounts
SELECT 'Test accounts:' as status;
SELECT id, email, user_type, is_verified, created_at 
FROM users 
WHERE email IN ('joeltiago@gmail.com', 'admin@test.com', 'customer@test.com', 'runner@test.com', 'business@test.com')
ORDER BY email;

-- 3. Check auth.users table
SELECT 'Checking auth.users...' as status;
SELECT COUNT(*) as auth_users_count FROM auth.users;

-- 4. Check errands table
SELECT 'Checking errands table...' as status;
SELECT COUNT(*) as total_errands FROM errands;

-- 5. Check if RLS is enabled
SELECT 'Checking Row Level Security...' as status;
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'errands', 'runner_applications', 'payments');

-- 6. Test permissions
SELECT 'Testing permissions...' as status;
SELECT current_user as current_role, session_user as session_user;

-- If you see errors here, your database needs setup 