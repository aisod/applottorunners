-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE errands ENABLE ROW LEVEL SECURITY;
ALTER TABLE runner_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE errand_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view all profiles" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (true);

CREATE POLICY "Users can delete their own profile" ON users
    FOR DELETE USING (auth.uid() = id);

-- Errands table policies
CREATE POLICY "Anyone can view posted errands" ON errands
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create errands" ON errands
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own errands or accepted errands" ON errands
    FOR UPDATE USING (
        auth.uid() = customer_id OR 
        auth.uid() = runner_id
    ) WITH CHECK (
        auth.uid() = customer_id OR 
        auth.uid() = runner_id
    );

CREATE POLICY "Users can delete their own errands" ON errands
    FOR DELETE USING (auth.uid() = customer_id);

-- Runner applications table policies
CREATE POLICY "Users can view all runner applications" ON runner_applications
    FOR SELECT USING (true);

CREATE POLICY "Users can create their own runner application" ON runner_applications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own runner application" ON runner_applications
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own runner application" ON runner_applications
    FOR DELETE USING (auth.uid() = user_id);

-- Errand updates table policies
CREATE POLICY "Anyone can view errand updates" ON errand_updates
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create errand updates" ON errand_updates
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own errand updates" ON errand_updates
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own errand updates" ON errand_updates
    FOR DELETE USING (auth.uid() = user_id);

-- Reviews table policies
CREATE POLICY "Anyone can view reviews" ON reviews
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create reviews" ON reviews
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own reviews" ON reviews
    FOR UPDATE USING (auth.uid() = reviewer_id) WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Users can delete their own reviews" ON reviews
    FOR DELETE USING (auth.uid() = reviewer_id);

-- Payments table policies
CREATE POLICY "Users can view their own payments" ON payments
    FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = runner_id);

CREATE POLICY "System can create payments" ON payments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "System can update payments" ON payments
    FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = runner_id);

-- Storage policies
CREATE POLICY "Anyone can view errand images" ON storage.objects
    FOR SELECT USING (bucket_id = 'errand-images');

CREATE POLICY "Authenticated users can upload errand images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'errand-images' AND auth.role() = 'authenticated');

CREATE POLICY "Users can update their own errand images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'errand-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own errand images" ON storage.objects
    FOR DELETE USING (bucket_id = 'errand-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

CREATE POLICY "Authenticated users can upload profile images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.role() = 'authenticated');

CREATE POLICY "Users can update their own profile images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own profile images" ON storage.objects
    FOR DELETE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Only users can view their verification docs" ON storage.objects
    FOR SELECT USING (bucket_id = 'verification-docs' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Authenticated users can upload verification docs" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'verification-docs' AND auth.role() = 'authenticated');

CREATE POLICY "Users can update their own verification docs" ON storage.objects
    FOR UPDATE USING (bucket_id = 'verification-docs' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own verification docs" ON storage.objects
    FOR DELETE USING (bucket_id = 'verification-docs' AND auth.uid()::text = (storage.foldername(name))[1]);