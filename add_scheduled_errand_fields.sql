-- Add fields for scheduled errand notifications
-- This migration adds fields to track scheduled errand times and notification status

-- Add scheduled time fields to errands table
ALTER TABLE errands ADD COLUMN IF NOT EXISTS scheduled_start_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE errands ADD COLUMN IF NOT EXISTS scheduled_end_time TIMESTAMP WITH TIME ZONE;

-- Add notification tracking fields
ALTER TABLE errands ADD COLUMN IF NOT EXISTS notification_5min_sent BOOLEAN DEFAULT false;
ALTER TABLE errands ADD COLUMN IF NOT EXISTS notification_10min_sent BOOLEAN DEFAULT false;
ALTER TABLE errands ADD COLUMN IF NOT EXISTS notification_1hour_sent BOOLEAN DEFAULT false;
ALTER TABLE errands ADD COLUMN IF NOT EXISTS notification_daily_sent DATE[] DEFAULT '{}';
ALTER TABLE errands ADD COLUMN IF NOT EXISTS notification_start_sent BOOLEAN DEFAULT false;

-- Add indexes for better performance on scheduled errand queries
CREATE INDEX IF NOT EXISTS idx_errands_scheduled_start_time ON errands(scheduled_start_time);
CREATE INDEX IF NOT EXISTS idx_errands_is_immediate_scheduled ON errands(is_immediate, scheduled_start_time);
CREATE INDEX IF NOT EXISTS idx_errands_notification_status ON errands(notification_5min_sent, notification_10min_sent, notification_1hour_sent, notification_start_sent);

-- Add comments to document the new fields
COMMENT ON COLUMN errands.scheduled_start_time IS 'When the scheduled errand should start';
COMMENT ON COLUMN errands.scheduled_end_time IS 'When the scheduled errand should end';
COMMENT ON COLUMN errands.notification_5min_sent IS 'Whether 5-minute reminder was sent';
COMMENT ON COLUMN errands.notification_10min_sent IS 'Whether 10-minute reminder was sent';
COMMENT ON COLUMN errands.notification_1hour_sent IS 'Whether 1-hour reminder was sent';
COMMENT ON COLUMN errands.notification_daily_sent IS 'Array of dates when daily reminders were sent';
COMMENT ON COLUMN errands.notification_start_sent IS 'Whether start time notification was sent';

-- Update existing errands to set scheduled times based on time_limit_hours
-- This is a one-time migration for existing data
UPDATE errands 
SET scheduled_start_time = created_at + (time_limit_hours || ' hours')::INTERVAL
WHERE is_immediate = false AND scheduled_start_time IS NULL;

-- Add function to calculate scheduled times for new errands
CREATE OR REPLACE FUNCTION calculate_scheduled_times()
RETURNS TRIGGER AS $$
BEGIN
  -- For scheduled errands, set start time based on time_limit_hours
  IF NEW.is_immediate = false AND NEW.scheduled_start_time IS NULL THEN
    NEW.scheduled_start_time = NEW.created_at + (NEW.time_limit_hours || ' hours')::INTERVAL;
    NEW.scheduled_end_time = NEW.scheduled_start_time + INTERVAL '1 hour';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically calculate scheduled times
DROP TRIGGER IF EXISTS trigger_calculate_scheduled_times ON errands;
CREATE TRIGGER trigger_calculate_scheduled_times
  BEFORE INSERT ON errands
  FOR EACH ROW
  EXECUTE FUNCTION calculate_scheduled_times();

-- Add function to reset daily notifications
CREATE OR REPLACE FUNCTION reset_daily_notifications()
RETURNS void AS $$
BEGIN
  -- Clear daily notification arrays for the current day
  UPDATE errands 
  SET notification_daily_sent = array_remove(notification_daily_sent, CURRENT_DATE::text::date)
  WHERE notification_daily_sent @> ARRAY[CURRENT_DATE::text::date];
END;
$$ LANGUAGE plpgsql;

-- Add function to reset all notification flags (for testing)
CREATE OR REPLACE FUNCTION reset_notification_flags()
RETURNS void AS $$
BEGIN
  UPDATE errands 
  SET notification_5min_sent = false,
      notification_10min_sent = false,
      notification_1hour_sent = false,
      notification_start_sent = false,
      notification_daily_sent = '{}'
  WHERE is_immediate = false;
END;
$$ LANGUAGE plpgsql;

-- Add validation to ensure scheduled times are set for non-immediate errands
ALTER TABLE errands ADD CONSTRAINT check_scheduled_times 
CHECK (
  (is_immediate = true) OR 
  (is_immediate = false AND scheduled_start_time IS NOT NULL)
);

