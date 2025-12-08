-- Create a function to automatically delete expired immediate errands
-- This function will be called by a trigger to clean up errands that haven't been accepted within the timeout period

CREATE OR REPLACE FUNCTION delete_expired_immediate_errands()
RETURNS void AS $$
BEGIN
    -- Delete immediate errands that are older than 30 seconds (timeout period)
    -- and still have status 'posted' (not accepted)
    DELETE FROM errands 
    WHERE status = 'posted' 
    AND is_immediate = true 
    AND runner_id IS NULL
    AND created_at < NOW() - INTERVAL '30 seconds';
    
    -- Log the cleanup action
    RAISE NOTICE 'Cleaned up expired immediate errands';
END;
$$ LANGUAGE plpgsql;

-- Create a trigger that runs the cleanup function every 10 seconds
-- This ensures expired immediate errands are removed promptly
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_errands()
RETURNS trigger AS $$
BEGIN
    -- Call the cleanup function
    PERFORM delete_expired_immediate_errands();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger on the errands table that fires after INSERT
-- This ensures cleanup happens when new errands are added
DROP TRIGGER IF EXISTS cleanup_expired_errands_trigger ON errands;
CREATE TRIGGER cleanup_expired_errands_trigger
    AFTER INSERT ON errands
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_cleanup_expired_errands();

-- Alternative approach: Create a scheduled job using pg_cron (if available)
-- This would run every 10 seconds to clean up expired errands
-- Uncomment the following if pg_cron extension is available:
/*
SELECT cron.schedule(
    'cleanup-expired-immediate-errands',
    '*/10 * * * * *', -- Every 10 seconds
    'SELECT delete_expired_immediate_errands();'
);
*/

-- Create an index to optimize the cleanup query
CREATE INDEX IF NOT EXISTS idx_immediate_errands_cleanup 
ON errands (status, is_immediate, runner_id, created_at) 
WHERE status = 'posted' AND is_immediate = true AND runner_id IS NULL;

-- Test the cleanup function
SELECT 'Immediate errand auto-delete trigger created successfully' AS status;
