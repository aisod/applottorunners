-- Manual cleanup function for immediate errands
-- This function can be called manually or scheduled to run periodically

-- Create a function to manually delete expired immediate errands
CREATE OR REPLACE FUNCTION cleanup_expired_immediate_errands()
RETURNS TABLE(deleted_count bigint) AS $$
DECLARE
    deleted_count bigint;
BEGIN
    -- Delete immediate errands that are older than 30 seconds and not accepted
    WITH deleted AS (
        DELETE FROM errands 
        WHERE status = 'posted' 
        AND is_immediate = true 
        AND runner_id IS NULL
        AND created_at < NOW() - INTERVAL '30 seconds'
        RETURNING id
    )
    SELECT COUNT(*) INTO deleted_count FROM deleted;
    
    -- Log the cleanup action
    RAISE NOTICE 'Cleaned up % expired immediate errands', deleted_count;
    
    -- Return the count of deleted errands
    RETURN QUERY SELECT deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Test the cleanup function
SELECT 'Testing cleanup function...' AS status;

-- Show current immediate errands before cleanup
SELECT 'Immediate errands before cleanup:' AS status;
SELECT id, title, status, is_immediate, created_at, runner_id 
FROM errands 
WHERE is_immediate = true 
ORDER BY created_at DESC;

-- Run the cleanup function
SELECT 'Running cleanup function...' AS status;
SELECT * FROM cleanup_expired_immediate_errands();

-- Show immediate errands after cleanup
SELECT 'Immediate errands after cleanup:' AS status;
SELECT id, title, status, is_immediate, created_at, runner_id 
FROM errands 
WHERE is_immediate = true 
ORDER BY created_at DESC;

-- Create a simple view to monitor immediate errands
CREATE OR REPLACE VIEW immediate_errands_monitor AS
SELECT 
    id,
    title,
    status,
    is_immediate,
    created_at,
    runner_id,
    EXTRACT(EPOCH FROM (NOW() - created_at)) AS age_seconds,
    CASE 
        WHEN runner_id IS NOT NULL THEN 'ACCEPTED'
        WHEN EXTRACT(EPOCH FROM (NOW() - created_at)) > 30 THEN 'EXPIRED'
        ELSE 'ACTIVE'
    END AS status_description
FROM errands 
WHERE is_immediate = true 
ORDER BY created_at DESC;

-- Show the monitor view
SELECT 'Immediate errands monitor:' AS status;
SELECT * FROM immediate_errands_monitor;
