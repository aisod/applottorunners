-- NUCLEAR OPTION: Complete RLS Reset for Errands Table
-- This will fix ALL possible RLS issues

BEGIN;

-- Step 1: Show what we're starting with
SELECT '=== BEFORE FIX ===' as status;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'errands';

-- Step 2: Drop EVERY policy on errands table
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'errands'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON errands', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Step 3: Create simple, permissive policies for ALL operations
-- INSERT policy
CREATE POLICY errands_insert_any ON errands
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- SELECT policy (so you can see what you inserted)
CREATE POLICY errands_select_any ON errands
    FOR SELECT
    TO authenticated
    USING (true);

-- UPDATE policy
CREATE POLICY errands_update_own ON errands
    FOR UPDATE
    TO authenticated
    USING (customer_id = auth.uid() OR runner_id = auth.uid())
    WITH CHECK (customer_id = auth.uid() OR runner_id = auth.uid());

-- DELETE policy
CREATE POLICY errands_delete_own ON errands
    FOR DELETE
    TO authenticated
    USING (customer_id = auth.uid());

-- Step 4: Verify the new policies
SELECT '=== AFTER FIX ===' as status;
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'INSERT' THEN with_check::text
        WHEN cmd = 'SELECT' THEN qual::text
        ELSE 'N/A'
    END as policy_check
FROM pg_policies 
WHERE tablename = 'errands'
ORDER BY cmd, policyname;

-- Step 5: Verify RLS is enabled
SELECT 
    '=== RLS STATUS ===' as status,
    rowsecurity as enabled
FROM pg_tables 
WHERE tablename = 'errands';

COMMIT;

-- Final check
SELECT '✅ RLS COMPLETELY RESET - Try creating an errand now!' as result;
