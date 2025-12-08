-- Add notification tracking fields to transportation_bookings table
-- This migration adds fields to track scheduled transportation notifications similar to errands

-- Add notification tracking fields to transportation_bookings table
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS notification_5min_sent BOOLEAN DEFAULT false;
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS notification_10min_sent BOOLEAN DEFAULT false;
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS notification_1hour_sent BOOLEAN DEFAULT false;
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS notification_1day_sent BOOLEAN DEFAULT false;
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS notification_start_sent BOOLEAN DEFAULT false;
ALTER TABLE transportation_bookings ADD COLUMN IF NOT EXISTS notification_daily_sent DATE[] DEFAULT '{}';

-- Add indexes for better performance on scheduled transportation queries
CREATE INDEX IF NOT EXISTS idx_transportation_bookings_notification_status ON transportation_bookings(
    notification_5min_sent, 
    notification_10min_sent, 
    notification_1hour_sent, 
    notification_1day_sent, 
    notification_start_sent
);

CREATE INDEX IF NOT EXISTS idx_transportation_bookings_booking_datetime ON transportation_bookings(booking_date, booking_time);

-- Add comments to document the new fields
COMMENT ON COLUMN transportation_bookings.notification_5min_sent IS 'Whether 5-minute reminder was sent';
COMMENT ON COLUMN transportation_bookings.notification_10min_sent IS 'Whether 10-minute reminder was sent';
COMMENT ON COLUMN transportation_bookings.notification_1hour_sent IS 'Whether 1-hour reminder was sent';
COMMENT ON COLUMN transportation_bookings.notification_1day_sent IS 'Whether 1-day reminder was sent';
COMMENT ON COLUMN transportation_bookings.notification_start_sent IS 'Whether start time notification was sent';
COMMENT ON COLUMN transportation_bookings.notification_daily_sent IS 'Array of dates when daily reminders were sent';
