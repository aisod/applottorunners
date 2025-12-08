-- Create a function to automatically delete expired immediate transportation bookings
-- This function will be called by a trigger to clean up bookings that haven't been accepted within the timeout period

CREATE OR REPLACE FUNCTION delete_expired_immediate_transportation_bookings()
RETURNS void AS $$
BEGIN
    -- Delete immediate transportation bookings that are older than 40 seconds (timeout period)
    -- and still have status 'pending' (not accepted)
    DELETE FROM transportation_bookings 
    WHERE status = 'pending' 
    AND is_immediate = true 
    AND driver_id IS NULL
    AND created_at < NOW() - INTERVAL '40 seconds';
    
    -- Log the cleanup action
    RAISE NOTICE 'Cleaned up expired immediate transportation bookings';
END;
$$ LANGUAGE plpgsql;

-- Create a trigger that runs the cleanup function every 10 seconds
-- This ensures expired immediate transportation bookings are removed promptly
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_transportation_bookings()
RETURNS trigger AS $$
BEGIN
    -- Call the cleanup function
    PERFORM delete_expired_immediate_transportation_bookings();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger on the transportation_bookings table that fires after INSERT
-- This ensures cleanup happens when new bookings are added
DROP TRIGGER IF EXISTS cleanup_expired_transportation_bookings_trigger ON transportation_bookings;
CREATE TRIGGER cleanup_expired_transportation_bookings_trigger
    AFTER INSERT ON transportation_bookings
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_cleanup_expired_transportation_bookings();

-- Alternative approach: Create a scheduled job using pg_cron (if available)
-- This would run every 10 seconds to clean up expired bookings
-- Uncomment the following if pg_cron extension is available:
/*
SELECT cron.schedule(
    'cleanup-expired-immediate-transportation-bookings',
    '*/10 * * * * *', -- Every 10 seconds
    'SELECT delete_expired_immediate_transportation_bookings();'
);
*/

-- Create an index to optimize the cleanup query
CREATE INDEX IF NOT EXISTS idx_immediate_transportation_bookings_cleanup 
ON transportation_bookings (status, is_immediate, driver_id, created_at) 
WHERE status = 'pending' AND is_immediate = true AND driver_id IS NULL;

