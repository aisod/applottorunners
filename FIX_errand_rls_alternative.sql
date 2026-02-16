-- Alternative Fix: Temporarily Disable RLS for Testing
-- WARNING: This is for debugging only - not for production!

-- Show current status
SELECT 'Current RLS status:' as info;
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'errands';

-- Option 1: Disable RLS temporarily (for testing only)
-- ALTER TABLE errands DISABLE ROW LEVEL SECURITY;

-- Option 2: Create a super permissive policy
DROP POLICY IF EXISTS "Users can create errands" ON errands;
DROP POLICY IF EXISTS "Admins can create errands" ON errands;
DROP POLICY IF EXISTS errands_insert_policy ON errands;
DROP POLICY IF EXISTS errands_insert_authenticated ON errands;
DROP POLICY IF EXISTS errands_allow_authenticated_insert ON errands;

-- Create the most permissive policy possible
CREATE POLICY errands_insert_allow_all ON errands
    FOR INSERT
    WITH CHECK (true);

-- Verify
SELECT 'New policies:' as info;
SELECT policyname, cmd, with_check 
FROM pg_policies 
WHERE tablename = 'errands' AND cmd = 'INSERT';

SELECT '✅ If you see errands_insert_allow_all with WITH CHECK = true, the policy is correct' as result;
