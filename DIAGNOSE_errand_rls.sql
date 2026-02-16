-- Diagnostic Script to Check Errand RLS Policies
-- Run this to see what policies are currently active

-- 1. Show ALL policies on errands table
SELECT 
    '=== ALL POLICIES ON ERRANDS TABLE ===' as section;

SELECT 
    policyname,
    cmd as command,
    roles::text,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'errands'
ORDER BY cmd, policyname;

-- 2. Show specifically INSERT policies
SELECT 
    '=== INSERT POLICIES ONLY ===' as section;

SELECT 
    policyname,
    roles::text,
    with_check as check_expression
FROM pg_policies 
WHERE tablename = 'errands' 
AND cmd = 'INSERT';

-- 3. Check if RLS is enabled
SELECT 
    '=== RLS STATUS ===' as section;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'errands';

-- 4. Check for triggers that might set customer_id
SELECT 
    '=== TRIGGERS ON ERRANDS ===' as section;

SELECT 
    trigger_name,
    event_manipulation as event,
    action_timing as timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'errands'
ORDER BY trigger_name;

-- 5. Check current user authentication
SELECT 
    '=== CURRENT USER CHECK ===' as section;

SELECT 
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ NOT AUTHENTICATED'
        ELSE '✅ AUTHENTICATED'
    END as auth_status;

-- 6. Test the policy check
SELECT 
    '=== POLICY TEST ===' as section;

SELECT 
    'true' as simple_check_result,
    'This should allow insert if policy is: WITH CHECK (true)' as explanation;
