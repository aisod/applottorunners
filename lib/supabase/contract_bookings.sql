-- Contract Bookings Table
-- This table stores long-term contract bookings for transportation services

CREATE TABLE contract_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  vehicle_type_id UUID REFERENCES vehicle_types(id) NOT NULL,
  pickup_location TEXT NOT NULL,
  pickup_lat DECIMAL(10, 8),
  pickup_lng DECIMAL(11, 8),
  dropoff_location TEXT NOT NULL,
  dropoff_lat DECIMAL(10, 8),
  dropoff_lng DECIMAL(11, 8),
  passenger_count INTEGER DEFAULT 1,
  contract_start_date DATE NOT NULL,
  contract_start_time TIME NOT NULL,
  contract_duration_type VARCHAR(20) NOT NULL CHECK (contract_duration_type IN ('weekly', 'monthly', 'yearly')),
  contract_duration_value INTEGER NOT NULL, -- Number of weeks/months/years
  contract_end_date DATE NOT NULL,
  description TEXT NOT NULL,
  special_requests TEXT,
  estimated_price DECIMAL(10, 2),
  final_price DECIMAL(10, 2),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'active', 'completed', 'expired')),
  payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
  payment_frequency VARCHAR(20) DEFAULT 'monthly' CHECK (payment_frequency IN ('weekly', 'monthly', 'yearly')),
  contract_reference VARCHAR(20) UNIQUE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX idx_contract_bookings_user ON contract_bookings(user_id, status);
CREATE INDEX idx_contract_bookings_vehicle ON contract_bookings(vehicle_type_id, status);
CREATE INDEX idx_contract_bookings_dates ON contract_bookings(contract_start_date, contract_end_date, status);
CREATE INDEX idx_contract_bookings_duration ON contract_bookings(contract_duration_type, status);

-- Add updated_at trigger
CREATE TRIGGER update_contract_bookings_updated_at 
  BEFORE UPDATE ON contract_bookings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE contract_bookings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own contract bookings
CREATE POLICY "Users can view own contract bookings" ON contract_bookings 
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own contract bookings
CREATE POLICY "Users can insert own contract bookings" ON contract_bookings 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own pending contract bookings
CREATE POLICY "Users can update own pending contract bookings" ON contract_bookings 
  FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Admins can manage all contract bookings
CREATE POLICY "Admins can manage all contract bookings" ON contract_bookings 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type IN ('admin')
    )
  );


