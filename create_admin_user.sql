-- Create Admin User Script
-- Run this in your Supabase SQL Editor to create your admin account

-- Function to insert users into auth.users table (if not exists)
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
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Create your admin account
DO $$
DECLARE
  admin_id uuid;
BEGIN
  -- Create auth user
  admin_id := insert_user_to_auth('joeltiago@gmail.com', '12345678');
  
  -- Insert user profile
  INSERT INTO users (id, email, full_name, phone, user_type, is_verified, has_vehicle, location_address) VALUES
    (admin_id, 'joeltiago@gmail.com', 'Joel Tiago', '+264-81-000000', 'admin', true, false, 'Windhoek, Namibia');
  
  RAISE NOTICE 'Admin account created successfully for joeltiago@gmail.com';
END $$;

-- Clean up function
DROP FUNCTION IF EXISTS insert_user_to_auth;

SELECT 'Admin account creation completed!' as status; 