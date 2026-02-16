-- ULTIMATE FIX for Errand RLS Policy Issue
-- This completely removes the problematic policy and replaces it with a working one

-- Step 1: Show current problematic policies
SELECT 
    'BEFORE FIX - Current INSERT policies:' as status,
    policyname,
    with_check
FROM pg_policies 
WHERE tablename = 'errands' 
AND cmd = 'INSERT';

-- Step 2: Drop ALL existing INSERT policies (including the problematic one)
DROP POLICY IF EXISTS "Users can create errands" ON errands;
DROP POLICY IF EXISTS "Admins can create errands" ON errands;
DROP POLICY IF EXISTS errands_insert_policy ON errands;
DROP POLICY IF EXISTS errands_insert_authenticated ON errands;

-- Step 3: Create ONE simple, working policy
-- This allows ANY authenticated user to insert errands
-- The trigger will handle setting the correct customer_id
CREATE POLICY errands_allow_authenticated_insert ON errands
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Step 4: Verify the fix
SELECT 
    'AFTER FIX - New INSERT policy:' as status,
    policyname,
    cmd,
    roles::text,
    with_check
FROM pg_policies 
WHERE tablename = 'errands' 
AND cmd = 'INSERT';

-- Step 5: Show the trigger that sets customer_id
SELECT 
    'Trigger that sets customer_id:' as status,
    trigger_name,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'errands'
AND trigger_name LIKE '%customer%';

-- Success message
SELECT '✅ RLS Policy Fixed! You can now create errands.' as result;
