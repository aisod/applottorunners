-- Users table extending auth.users
CREATE TABLE users (
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

-- Errands table
CREATE TABLE errands (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    runner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('grocery', 'delivery', 'document', 'shopping', 'other')),
    price_amount DECIMAL(10,2) NOT NULL,
    time_limit_hours INTEGER NOT NULL DEFAULT 24,
    status TEXT NOT NULL DEFAULT 'posted' CHECK (status IN ('posted', 'pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
    location_address TEXT NOT NULL,
    pickup_address TEXT,
    delivery_address TEXT,
    image_urls TEXT[] DEFAULT '{}',
    special_instructions TEXT,
    requires_vehicle BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Chat conversations table
CREATE TABLE chat_conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    runner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    closed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(errand_id)
);

-- Chat messages table
CREATE TABLE chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES chat_conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'location', 'status_update')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Runner applications table
CREATE TABLE runner_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    has_vehicle BOOLEAN NOT NULL DEFAULT false,
    vehicle_type TEXT,
    vehicle_details TEXT,
    license_number TEXT,
    verification_documents TEXT[],
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Errand updates/messages table
CREATE TABLE errand_updates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    status_change TEXT,
    image_url TEXT,
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ratings and reviews table
CREATE TABLE reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    reviewee_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payments/Transactions table
CREATE TABLE payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    errand_id UUID REFERENCES errands(id) ON DELETE CASCADE NOT NULL,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    runner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method TEXT DEFAULT 'stripe',
    transaction_id TEXT,
    stripe_payment_intent_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    refunded_at TIMESTAMP WITH TIME ZONE,
    refund_amount DECIMAL(10,2)
);

-- Create indexes for better performance
CREATE INDEX idx_errands_status ON errands(status);
CREATE INDEX idx_errands_customer_id ON errands(customer_id);
CREATE INDEX idx_errands_runner_id ON errands(runner_id);
CREATE INDEX idx_chat_conversations_errand_id ON chat_conversations(errand_id);
CREATE INDEX idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_errands_category ON errands(category);
CREATE INDEX idx_errands_created_at ON errands(created_at);
CREATE INDEX idx_runner_applications_user_id ON runner_applications(user_id);
CREATE INDEX idx_runner_applications_status ON runner_applications(verification_status);
CREATE INDEX idx_errand_updates_errand_id ON errand_updates(errand_id);
CREATE INDEX idx_reviews_errand_id ON reviews(errand_id);
CREATE INDEX idx_payments_errand_id ON payments(errand_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created_at ON payments(created_at);

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
('errand-images', 'errand-images', true),
('profiles', 'profiles', true),
('verification-docs', 'verification-docs', false);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to tables that need updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_errands_updated_at BEFORE UPDATE ON errands
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_runner_applications_updated_at BEFORE UPDATE ON runner_applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();