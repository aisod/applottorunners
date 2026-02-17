-- Allow runners to UPDATE errands when accepting (status posted/pending, runner_id null).
-- Without this, only customer_id = auth.uid() or runner_id = auth.uid() can update,
-- so the runner's accept PATCH updates 0 rows and PostgREST returns 406.

-- Add policy: any authenticated user can update an errand that is available to accept
-- (posted or pending, no runner yet), and only to set themselves as runner and status accepted.
CREATE POLICY errands_update_runner_accept ON errands
    FOR UPDATE
    TO authenticated
    USING (
        status IN ('posted', 'pending')
        AND runner_id IS NULL
    )
    WITH CHECK (
        runner_id = auth.uid()
        AND status = 'accepted'
    );

COMMENT ON POLICY errands_update_runner_accept ON errands IS
    'Allows runners to accept available errands (set runner_id and status to accepted).';
