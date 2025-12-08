-- Add notification tracking columns to contract_bookings table
ALTER TABLE contract_bookings 
ADD COLUMN IF NOT EXISTS notification_5min_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_10min_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_1hour_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_start_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_daily_sent TEXT[] DEFAULT '{}';

-- Add notification tracking columns to bus_service_bookings table
ALTER TABLE bus_service_bookings 
ADD COLUMN IF NOT EXISTS notification_5min_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_10min_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_1hour_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_start_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS notification_daily_sent TEXT[] DEFAULT '{}';

-- Add indexes for notification columns
CREATE INDEX IF NOT EXISTS idx_contract_bookings_notifications 
ON contract_bookings(notification_5min_sent, notification_10min_sent, notification_1hour_sent, notification_start_sent);

CREATE INDEX IF NOT EXISTS idx_bus_service_bookings_notifications 
ON bus_service_bookings(notification_5min_sent, notification_10min_sent, notification_1hour_sent, notification_start_sent);

-- Update notifications table to support contract and bus booking references
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS contract_booking_id UUID REFERENCES contract_bookings(id),
ADD COLUMN IF NOT EXISTS bus_booking_id UUID REFERENCES bus_service_bookings(id);

-- Add indexes for the new foreign key references
CREATE INDEX IF NOT EXISTS idx_notifications_contract_booking 
ON notifications(contract_booking_id);

CREATE INDEX IF NOT EXISTS idx_notifications_bus_booking 
ON notifications(bus_booking_id);
