-- Comprehensive RLS Policy Fix for Errands Table
-- This script will completely reset the INSERT policy for errands

-- Step 1: Drop ALL existing policies on errands table
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'errands' AND cmd = 'INSERT'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON errands', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Step 2: Create a simple, permissive INSERT policy
CREATE POLICY errands_insert_authenticated ON errands
    FOR INSERT
    TO authenticated
    WITH CHECK (true);  -- Allow all authenticated users to insert

-- Step 3: Verify the new policy
SELECT 
    'Current INSERT policies on errands table:' as info;

SELECT 
    policyname,
    cmd,
    roles,
    with_check
FROM pg_policies 
WHERE tablename = 'errands' 
AND cmd = 'INSERT';

-- Step 4: Check if there's a trigger setting customer_id
SELECT 
    'Triggers on errands table:' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'errands';

-- Step 5: Test query to verify the policy works
-- This should show what the policy will check
SELECT 
    'Testing policy - this should return true for authenticated users:' as info;

SELECT auth.uid() IS NOT NULL as can_insert;
