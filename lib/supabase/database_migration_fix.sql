-- ====================================================================
-- LOTTO RUNNERS DATABASE MIGRATION - CRITICAL FIXES
-- ====================================================================
-- This script fixes critical issues in the existing database schema
-- Run this on your existing Supabase database to fix column and bucket mismatches

-- 1. Fix column name mismatch in users table
-- Change profile_image_url to avatar_url to match Flutter app code
DO $$
BEGIN
    -- Check if the old column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'users' AND column_name = 'profile_image_url') THEN
        -- Rename the column
        ALTER TABLE users RENAME COLUMN profile_image_url TO avatar_url;
        RAISE NOTICE 'Column profile_image_url renamed to avatar_url';
    END IF;
END $$;

-- 2. Fix storage bucket name mismatch
-- Update bucket from 'profile-images' to 'profiles'
DO $$
BEGIN
    -- Check if the old bucket exists
    IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'profile-images') THEN
        -- Update bucket name
        UPDATE storage.buckets SET id = 'profiles' WHERE id = 'profile-images';
        RAISE NOTICE 'Storage bucket renamed from profile-images to profiles';
    END IF;
END $$;

-- 3. Add missing RLS policy for payments table
DO $$
BEGIN
    -- Enable RLS if not already enabled
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'payments' AND rowsecurity = true) THEN
        ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS enabled for payments table';
    END IF;
END $$;

-- 4. Create missing payment policies
DO $$
BEGIN
    -- Drop existing policies if they exist and recreate them
    DROP POLICY IF EXISTS "Users can view their own payments" ON payments;
    DROP POLICY IF EXISTS "System can create payments" ON payments;
    DROP POLICY IF EXISTS "System can update payments" ON payments;
    
    -- Create new policies
    CREATE POLICY "Users can view their own payments" ON payments
        FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = runner_id);
    
    CREATE POLICY "System can create payments" ON payments
        FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    
    CREATE POLICY "System can update payments" ON payments
        FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = runner_id);
    
    RAISE NOTICE 'Payment policies created successfully';
END $$;

-- 5. Fix storage policies for new bucket name
DO $$
BEGIN
    -- Drop old policies
    DROP POLICY IF EXISTS "Anyone can view profile images" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can upload profile images" ON storage.objects;
    DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
    DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;
    
    -- Create new policies with correct bucket name
    CREATE POLICY "Anyone can view profile images" ON storage.objects
        FOR SELECT USING (bucket_id = 'profiles');
    
    CREATE POLICY "Authenticated users can upload profile images" ON storage.objects
        FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.role() = 'authenticated');
    
    CREATE POLICY "Users can update their own profile images" ON storage.objects
        FOR UPDATE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);
    
    CREATE POLICY "Users can delete their own profile images" ON storage.objects
        FOR DELETE USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);
    
    RAISE NOTICE 'Storage policies updated for profiles bucket';
END $$;

-- 6. Add missing updated_at triggers
DO $$
BEGIN
    -- Add triggers for tables that don't have them
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_runner_applications_updated_at') THEN
        CREATE TRIGGER update_runner_applications_updated_at BEFORE UPDATE ON runner_applications
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Updated_at trigger added to runner_applications';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_payments_updated_at') THEN
        CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Updated_at trigger added to payments';
    END IF;
END $$;

-- 7. Create missing storage buckets if they don't exist
DO $$
BEGIN
    -- Ensure all required buckets exist
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'errand-images') THEN
        INSERT INTO storage.buckets (id, name, public) VALUES ('errand-images', 'errand-images', true);
        RAISE NOTICE 'Created errand-images bucket';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'profiles') THEN
        INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true);
        RAISE NOTICE 'Created profiles bucket';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'verification-docs') THEN
        INSERT INTO storage.buckets (id, name, public) VALUES ('verification-docs', 'verification-docs', false);
        RAISE NOTICE 'Created verification-docs bucket';
    END IF;
END $$;

-- 8. Create any missing indexes
DO $$
BEGIN
    -- Add any missing indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_user_type') THEN
        CREATE INDEX idx_users_user_type ON users(user_type);
        RAISE NOTICE 'Created index on users.user_type';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_is_verified') THEN
        CREATE INDEX idx_users_is_verified ON users(is_verified);
        RAISE NOTICE 'Created index on users.is_verified';
    END IF;
END $$;

-- 9. Verify the fixes
SELECT 
    'Database migration completed successfully!' as status,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'avatar_url') as avatar_column_exists,
    (SELECT COUNT(*) FROM storage.buckets WHERE id = 'profiles') as profiles_bucket_exists,
    (SELECT COUNT(*) FROM information_schema.table_privileges WHERE table_name = 'payments' AND privilege_type = 'SELECT') as payments_policies_exist; 