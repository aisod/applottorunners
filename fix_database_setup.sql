-- ====================================================================
-- LOTTO RUNNERS DATABASE SAFE SETUP (Handles Existing Users)
-- ====================================================================
-- This script won't fail if users already exist

-- 1. Create tables (if they don't exist)
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

CREATE TABLE IF NOT EXISTS errand_updates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    status_change TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    reviewee_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE errands ENABLE ROW LEVEL SECURITY;
ALTER TABLE runner_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE errand_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- 3. Create storage bucket (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- 4. Safe user creation function
CREATE OR REPLACE FUNCTION create_user_if_not_exists(
    p_email text,
    p_password text,
    p_full_name text,
    p_phone text,
    p_user_type text,
    p_location text DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    user_id uuid;
    encrypted_pw text;
    existing_user_id uuid;
BEGIN
    -- Check if user already exists in auth.users
    SELECT id INTO existing_user_id FROM auth.users WHERE email = p_email;
    
    IF existing_user_id IS NOT NULL THEN
        -- User exists, check if profile exists
        IF NOT EXISTS (SELECT 1 FROM users WHERE id = existing_user_id) THEN
            -- Create profile for existing auth user
            INSERT INTO users (id, email, full_name, phone, user_type, is_verified, location_address)
            VALUES (existing_user_id, p_email, p_full_name, p_phone, p_user_type, true, p_location);
        END IF;
        RETURN existing_user_id;
    END IF;
    
    -- Create new user
    user_id := gen_random_uuid();
    encrypted_pw := crypt(p_password, gen_salt('bf'));
    
    INSERT INTO auth.users
        (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
    VALUES
        (gen_random_uuid(), user_id, 'authenticated', 'authenticated', p_email, encrypted_pw, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), '', '', '', '');
    
    INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    VALUES
        (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, p_email)::jsonb, 'email', NOW(), NOW(), NOW());
    
    -- Create user profile
    INSERT INTO users (id, email, full_name, phone, user_type, is_verified, location_address)
    VALUES (user_id, p_email, p_full_name, p_phone, p_user_type, true, p_location);
    
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Create test users (safely)
DO $$
DECLARE
    admin_id uuid;
    customer_id uuid;
    runner_id uuid;
    business_id uuid;
    joel_admin_id uuid;
BEGIN
    -- Create test accounts
    admin_id := create_user_if_not_exists('admin@test.com', 'admin123', 'Test Admin', '+264-61-000000', 'admin', 'Admin Office, Windhoek');
    customer_id := create_user_if_not_exists('customer@test.com', 'password123', 'Test Customer', '+264-61-111111', 'individual', 'Customer Street, Windhoek');
    runner_id := create_user_if_not_exists('runner@test.com', 'password123', 'Test Runner', '+264-61-222222', 'runner', 'Runner Road, Windhoek');
    business_id := create_user_if_not_exists('business@test.com', 'password123', 'Test Business', '+264-61-333333', 'business', 'Business Blvd, Windhoek');
    joel_admin_id := create_user_if_not_exists('joeltiago@gmail.com', '12345678', 'Joel Tiago', '+264-81-000000', 'admin', 'Windhoek, Namibia');
    
    -- Create sample errands (only if they don't exist)
    INSERT INTO errands (customer_id, title, description, category, price_amount, time_limit_hours, status, location_address, pickup_address, delivery_address, special_instructions, requires_vehicle)
    SELECT customer_id, 'Grocery Shopping', 'Buy groceries from the shopping list', 'grocery', 25.00, 3, 'posted', 'Customer Street, Windhoek', 'Shoprite Windhoek', 'Customer Street, Windhoek', 'Fresh produce preferred', false
    WHERE NOT EXISTS (SELECT 1 FROM errands WHERE title = 'Grocery Shopping' AND customer_id = customer_id);
    
    INSERT INTO errands (customer_id, title, description, category, price_amount, time_limit_hours, status, location_address, pickup_address, delivery_address, special_instructions, requires_vehicle)
    SELECT customer_id, 'Document Delivery', 'Deliver important documents', 'document', 15.00, 2, 'posted', 'Customer Street, Windhoek', 'Customer Street, Windhoek', 'Business District, Windhoek', 'Handle with care', false
    WHERE NOT EXISTS (SELECT 1 FROM errands WHERE title = 'Document Delivery' AND customer_id = customer_id);
    
    -- Create runner application (if not exists)
    INSERT INTO runner_applications (user_id, has_vehicle, vehicle_type, vehicle_details, license_number, verification_status, reviewed_at)
    SELECT runner_id, true, 'car', '2020 Toyota Corolla', 'DL123456', 'approved', NOW()
    WHERE NOT EXISTS (SELECT 1 FROM runner_applications WHERE user_id = runner_id);
    
    RAISE NOTICE 'Database setup completed successfully!';
    RAISE NOTICE 'Test accounts available:';
    RAISE NOTICE '- Admin: admin@test.com / admin123';
    RAISE NOTICE '- Customer: customer@test.com / password123';
    RAISE NOTICE '- Runner: runner@test.com / password123';
    RAISE NOTICE '- Business: business@test.com / password123';
    RAISE NOTICE '- Joel Admin: joeltiago@gmail.com / 12345678';
END $$;

-- 6. Create RLS policies (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view all profiles' AND tablename = 'users') THEN
        CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own profile' AND tablename = 'users') THEN
        CREATE POLICY "Users can insert their own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own profile' AND tablename = 'users') THEN
        CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view posted errands' AND tablename = 'errands') THEN
        CREATE POLICY "Anyone can view posted errands" ON errands FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can create errands' AND tablename = 'errands') THEN
        CREATE POLICY "Users can create errands" ON errands FOR INSERT WITH CHECK (auth.uid() = customer_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their errands' AND tablename = 'errands') THEN
        CREATE POLICY "Users can update their errands" ON errands FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = runner_id) WITH CHECK (auth.uid() = customer_id OR auth.uid() = runner_id);
    END IF;
END $$;

-- 7. Create indexes (if not exists)
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_is_verified ON users(is_verified);
CREATE INDEX IF NOT EXISTS idx_errands_status ON errands(status);
CREATE INDEX IF NOT EXISTS idx_errands_customer_id ON errands(customer_id);
CREATE INDEX IF NOT EXISTS idx_errands_runner_id ON errands(runner_id);

-- 8. Clean up function
DROP FUNCTION IF EXISTS create_user_if_not_exists;

-- 9. Final verification
SELECT 'Database setup completed successfully!' as status;
SELECT 'User accounts:' as info;
SELECT email, user_type, is_verified FROM users ORDER BY user_type, email; 