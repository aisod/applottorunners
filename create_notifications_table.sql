-- Create notifications table for ride request notifications
-- This table will store notifications for runners when new transportation bookings are created

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'transportation_request', 'errand_request', etc.
  booking_id UUID REFERENCES transportation_bookings(id) ON DELETE CASCADE,
  errand_id UUID REFERENCES errands(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (
    (booking_id IS NOT NULL AND errand_id IS NULL) OR
    (booking_id IS NULL AND errand_id IS NOT NULL) OR
    (booking_id IS NULL AND errand_id IS NULL)
  )
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Create RLS policies for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications" ON notifications
FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications" ON notifications
FOR UPDATE USING (auth.uid() = user_id);

-- System can insert notifications for users
CREATE POLICY "System can insert notifications" ON notifications
FOR INSERT WITH CHECK (true);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_notifications_updated_at();

-- Add comment to document the table
COMMENT ON TABLE notifications IS 'Stores notifications for users including ride requests and errand updates';
COMMENT ON COLUMN notifications.type IS 'Type of notification: transportation_request, errand_request, etc.';
COMMENT ON COLUMN notifications.booking_id IS 'Reference to transportation booking if notification is related to a ride request';
COMMENT ON COLUMN notifications.errand_id IS 'Reference to errand if notification is related to an errand';
