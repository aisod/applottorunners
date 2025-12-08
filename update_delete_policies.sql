-- Update RLS policies to allow users to delete their own completed items from history
-- This ensures users can only delete their own data, not others'

-- 1. Update errands delete policy to allow only customers to delete their own errands
-- Runners cannot delete errands as they belong to customers
DROP POLICY IF EXISTS "Users can delete their own errands" ON errands;
CREATE POLICY "Users can delete their own errands" ON errands
    FOR DELETE USING (
        auth.uid() = customer_id
    );

-- 2. Add transportation bookings delete policy to allow users to delete their own completed bookings
CREATE POLICY "Users can delete their own transportation bookings" ON transportation_bookings
    FOR DELETE USING (
        auth.uid() = user_id AND status = 'completed'
    );

-- Note: This policy only allows deletion of completed transportation bookings
-- to prevent users from deleting active bookings that might be in progress
