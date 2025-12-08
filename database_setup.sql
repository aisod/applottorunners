-- ====================================================================
-- LOTTO RUNNERS DATABASE COMPLETE SETUP
-- ====================================================================
-- Run this script in your Supabase SQL Editor to set up the complete database

-- 1. Create the users table (extending auth.users)
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    user_type TEXT NOT NULL CHECK (user_type IN ('runner', 'business', 'individual', 'admin')),
    is_verified BOOLEAN DEFAULT false,
    has_vehicle BOOLEAN DEFAULT false,
    location_address TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (id)
);

-- 2. Create the errands table
CREATE TABLE IF NOT EXISTS errands (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    runner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('grocery', 'delivery', 'document', 'shopping', 'other')),
    price_amount DECIMAL(10,2) NOT NULL,
    time_limit_hours INTEGER NOT NULL DEFAULT 24,
    status TEXT NOT NULL DEFAULT 'posted' CHECK (status IN ('posted', 'accepted', 'in_progress', 'completed', 'cancelled')),
    location_address TEXT NOT NULL,
    pickup_address TEXT,
    delivery_address TEXT,
    image_urls TEXT[] DEFAULT '{}',
    special_instructions TEXT,
    requires_vehicle BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 3. Create runner_applications table
CREATE TABLE IF NOT EXISTS runner_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    has_vehicle BOOLEAN DEFAULT false,
    vehicle_type TEXT,
    vehicle_details TEXT,
    license_number TEXT,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- 4. Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    runner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    payment_method TEXT,
    transaction_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create errand_updates table
CREATE TABLE IF NOT EXISTS errand_updates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    status_change TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    reviewee_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE errands ENABLE ROW LEVEL SECURITY;
ALTER TABLE runner_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE errand_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- 8. Create storage bucket for profiles if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- 9. Function to create auth users
CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', NOW(), NOW(), NOW());
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- 10. Create test users
DO $$
DECLARE
  admin_id uuid;
  customer_id uuid;
  runner_id uuid;
  business_id uuid;
  joel_admin_id uuid;
BEGIN
  -- Create test admin user
  admin_id := insert_user_to_auth('admin@test.com', 'admin123');
  
  -- Create regular customer
  customer_id := insert_user_to_auth('customer@test.com', 'password123');
  
  -- Create runner
  runner_id := insert_user_to_auth('runner@test.com', 'password123');
  
  -- Create business
  business_id := insert_user_to_auth('business@test.com', 'password123');
  
  -- Create Joel's admin account
  joel_admin_id := insert_user_to_auth('joeltiago@gmail.com', '12345678');
  
  -- Insert corresponding user profiles
  INSERT INTO users (id, email, full_name, phone, user_type, is_verified, has_vehicle, location_address) VALUES
    (admin_id, 'admin@test.com', 'Test Admin', '+264-61-000000', 'admin', true, false, 'Admin Office, Windhoek'),
    (customer_id, 'customer@test.com', 'Test Customer', '+264-61-111111', 'individual', true, false, 'Customer Street, Windhoek'),
    (runner_id, 'runner@test.com', 'Test Runner', '+264-61-222222', 'runner', true, true, 'Runner Road, Windhoek'),
    (business_id, 'business@test.com', 'Test Business', '+264-61-333333', 'business', true, false, 'Business Blvd, Windhoek'),
    (joel_admin_id, 'joeltiago@gmail.com', 'Joel Tiago', '+264-81-000000', 'admin', true, false, 'Windhoek, Namibia');
  
  -- Create sample errands
  INSERT INTO errands (customer_id, title, description, category, price_amount, time_limit_hours, status, location_address, pickup_address, delivery_address, special_instructions, requires_vehicle) VALUES
    (customer_id, 'Grocery Shopping', 'Buy groceries from the shopping list', 'grocery', 25.00, 3, 'posted', 'Customer Street, Windhoek', 'Shoprite Windhoek', 'Customer Street, Windhoek', 'Fresh produce preferred', false),
    (customer_id, 'Document Delivery', 'Deliver important documents', 'document', 15.00, 2, 'posted', 'Customer Street, Windhoek', 'Customer Street, Windhoek', 'Business District, Windhoek', 'Handle with care', false),
    (business_id, 'Package Delivery', 'Multiple package deliveries', 'delivery', 50.00, 4, 'posted', 'Business Blvd, Windhoek', 'Business Blvd, Windhoek', 'Various locations', 'Vehicle required', true);
  
  -- Create runner application
  INSERT INTO runner_applications (user_id, has_vehicle, vehicle_type, vehicle_details, license_number, verification_status, reviewed_at) VALUES
    (runner_id, true, 'car', '2020 Toyota Corolla', 'DL123456', 'approved', NOW());
  
  RAISE NOTICE 'Database setup completed successfully!';
  RAISE NOTICE 'Test accounts created:';
  RAISE NOTICE '- Admin: admin@test.com / admin123';
  RAISE NOTICE '- Customer: customer@test.com / password123';
  RAISE NOTICE '- Runner: runner@test.com / password123';
  RAISE NOTICE '- Business: business@test.com / password123';
  RAISE NOTICE '- Joel Admin: joeltiago@gmail.com / 12345678';
END $$;

-- 11. Create basic RLS policies
CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Anyone can view posted errands" ON errands FOR SELECT USING (true);
CREATE POLICY "Users can create errands" ON errands FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Users can update their errands" ON errands FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = runner_id) WITH CHECK (auth.uid() = customer_id OR auth.uid() = runner_id);

CREATE POLICY "Users can view their applications" ON runner_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create applications" ON runner_applications FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their payments" ON payments FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = runner_id);
CREATE POLICY "Users can view their updates" ON errand_updates FOR SELECT USING (true);
CREATE POLICY "Users can create updates" ON errand_updates FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view reviews" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can create reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- 12. Storage policies
CREATE POLICY "Users can upload own profile images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Public can view profile images" ON storage.objects
  FOR SELECT USING (bucket_id = 'profiles');

CREATE POLICY "Users can update own profile images" ON storage.objects
  FOR UPDATE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own profile images" ON storage.objects
  FOR DELETE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 13. Clean up function
DROP FUNCTION IF EXISTS insert_user_to_auth;

-- 14. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_is_verified ON users(is_verified);
CREATE INDEX IF NOT EXISTS idx_errands_status ON errands(status);
CREATE INDEX IF NOT EXISTS idx_errands_customer_id ON errands(customer_id);
CREATE INDEX IF NOT EXISTS idx_errands_runner_id ON errands(runner_id);

-- Success message
SELECT 'Database setup completed successfully!' as status,
       'You can now log in with any of the test accounts' as message; 