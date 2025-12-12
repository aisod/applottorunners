-- Bus Service Bookings Table
-- This table stores all bus service bookings separately from regular transportation bookings

CREATE TABLE bus_service_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  service_id UUID REFERENCES transportation_services(id) NOT NULL,
  pickup_location TEXT NOT NULL,
  pickup_lat DECIMAL(10, 8),
  pickup_lng DECIMAL(11, 8),
  dropoff_location TEXT NOT NULL,
  dropoff_lat DECIMAL(10, 8),
  dropoff_lng DECIMAL(11, 8),
  passenger_count INTEGER DEFAULT 1,
  booking_date DATE NOT NULL,
  booking_time TIME NOT NULL,
  special_requests TEXT,
  estimated_price DECIMAL(10, 2),
  final_price DECIMAL(10, 2),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')),
  payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
  booking_reference VARCHAR(20) UNIQUE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX idx_bus_service_bookings_user ON bus_service_bookings(user_id, status);
CREATE INDEX idx_bus_service_bookings_service ON bus_service_bookings(service_id, booking_date);
CREATE INDEX idx_bus_service_bookings_date ON bus_service_bookings(booking_date, status);

-- Add updated_at trigger
CREATE TRIGGER update_bus_service_bookings_updated_at 
  BEFORE UPDATE ON bus_service_bookings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE bus_service_bookings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own bookings
CREATE POLICY "Users can view own bus service bookings" ON bus_service_bookings 
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own bookings
CREATE POLICY "Users can insert own bus service bookings" ON bus_service_bookings 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own pending bookings
CREATE POLICY "Users can update own pending bus service bookings" ON bus_service_bookings 
  FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Admins can manage all bookings
CREATE POLICY "Admins can manage all bus service bookings" ON bus_service_bookings 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type IN ('admin')
    )
  );


