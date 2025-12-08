-- Fix RLS policies for errands table to allow runners to see their accepted orders
-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Anyone can view posted errands" ON errands;

-- Create a comprehensive policy that allows:
-- 1. Anyone to view posted errands (for discovery)
-- 2. Customers to view their own errands
-- 3. Runners to view errands they've accepted or are working on
CREATE POLICY "Comprehensive errand viewing policy" ON errands
    FOR SELECT USING (
        -- Anyone can view posted errands
        status = 'posted' OR
        -- Customers can view their own errands
        auth.uid() = customer_id OR
        -- Runners can view errands they've accepted, are working on, or completed
        auth.uid() = runner_id
    );

-- Ensure the policy is enabled
ALTER TABLE errands ENABLE ROW LEVEL SECURITY;

-- Verify the policy was created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'errands';
