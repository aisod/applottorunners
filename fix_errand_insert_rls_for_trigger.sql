-- Fix RLS policy for errands table to allow inserts with trigger
-- This fixes the issue where customer_id is set by a trigger instead of directly in the insert

-- Drop existing insert policy if it exists
DROP POLICY IF EXISTS errands_insert_policy ON errands;

-- Create new insert policy that allows authenticated users to insert errands
-- The trigger will set the customer_id, so we don't need to check it in the policy
CREATE POLICY errands_insert_policy ON errands
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow insert if the user is authenticated
        -- The trigger will ensure customer_id is set correctly
        auth.uid() IS NOT NULL
    );

-- Verify the policy was created
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
WHERE tablename = 'errands' 
AND policyname = 'errands_insert_policy';
