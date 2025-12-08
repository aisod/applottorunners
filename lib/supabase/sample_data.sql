-- Function to insert users into auth.users table
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

-- Insert sample users into auth.users first
DO $$
DECLARE
  admin_id uuid;
  customer1_id uuid;
  customer2_id uuid;
  runner1_id uuid;
  runner2_id uuid;
  business1_id uuid;
BEGIN
  -- Create auth users and get their IDs
  admin_id := insert_user_to_auth('admin@lottorunners.com', 'admin123');
  customer1_id := insert_user_to_auth('john.customer@example.com', 'password123');
  customer2_id := insert_user_to_auth('mary.shopper@example.com', 'password123');
  runner1_id := insert_user_to_auth('mike.runner@example.com', 'password123');
  runner2_id := insert_user_to_auth('sarah.delivery@example.com', 'password123');
  business1_id := insert_user_to_auth('contact@quickstore.com', 'password123');

  -- Insert corresponding user profiles
  INSERT INTO users (id, email, full_name, phone, user_type, is_verified, has_vehicle, location_address) VALUES
    (admin_id, 'admin@lottorunners.com', 'Admin User', '+264-61-000000', 'admin', true, false, 'Admin Office, Windhoek'),
    (customer1_id, 'john.customer@example.com', 'John Customer', '+1234567890', 'individual', true, false, '123 Oak Street, Downtown'),
    (customer2_id, 'mary.shopper@example.com', 'Mary Shopper', '+1234567891', 'individual', true, false, '456 Pine Avenue, Uptown'),
    (runner1_id, 'mike.runner@example.com', 'Mike Runner', '+1234567892', 'runner', true, true, '789 Main Street, Central'),
    (runner2_id, 'sarah.delivery@example.com', 'Sarah Delivery', '+1234567893', 'runner', true, false, '321 Elm Road, Westside'),
    (business1_id, 'contact@quickstore.com', 'QuickStore Business', '+1234567894', 'business', true, false, '555 Business Plaza, Commercial District');

  -- Insert sample errands
  INSERT INTO errands (customer_id, title, description, category, price_amount, time_limit_hours, status, location_address, pickup_address, delivery_address, special_instructions, requires_vehicle) VALUES
    (customer1_id, 'Grocery Shopping at Walmart', 'Need someone to buy groceries from the list I will provide. Please get fresh fruits and vegetables.', 'grocery', 25.00, 3, 'posted', '123 Oak Street, Downtown', 'Walmart Supercenter, 100 Store St', '123 Oak Street, Downtown', 'Please check expiration dates and choose fresh produce', false),
    (customer1_id, 'Document Delivery to Law Office', 'Important legal documents need to be delivered to Johnson & Associates Law Firm by 5 PM today.', 'document', 15.00, 6, 'posted', '123 Oak Street, Downtown', '123 Oak Street, Downtown', 'Johnson & Associates, 200 Legal Ave', 'Handle with care - very important documents', false),
    (customer2_id, 'Prescription Pickup', 'Pick up my prescription from CVS pharmacy. I will provide the prescription number and my ID details.', 'delivery', 10.00, 2, 'accepted', '456 Pine Avenue, Uptown', 'CVS Pharmacy, 300 Health St', '456 Pine Avenue, Uptown', 'Ask for prescription under Mary Shopper', false),
    (business1_id, 'Office Supply Delivery', 'Deliver office supplies to three different locations in the city. Vehicle required for multiple boxes.', 'delivery', 50.00, 8, 'posted', '555 Business Plaza, Commercial District', '555 Business Plaza, Commercial District', 'Multiple locations (details provided)', 'Heavy items - vehicle required', true),
    (customer1_id, 'Pet Food Shopping', 'Buy specific dog food brand from PetSmart. My dog has allergies so brand is very important.', 'shopping', 20.00, 4, 'completed', '123 Oak Street, Downtown', 'PetSmart, 400 Pet Ave', '123 Oak Street, Downtown', 'Only Hill\'s Science Diet - no substitutions', false);

  -- Update some errands with runner assignments
  UPDATE errands SET runner_id = runner2_id, accepted_at = NOW() - INTERVAL '2 hours' 
  WHERE title = 'Prescription Pickup';

  UPDATE errands SET runner_id = runner1_id, completed_at = NOW() - INTERVAL '1 day'
  WHERE title = 'Pet Food Shopping';

  -- Insert runner applications
  INSERT INTO runner_applications (user_id, has_vehicle, vehicle_type, vehicle_details, license_number, verification_status, reviewed_at) VALUES
    (runner1_id, true, 'car', '2020 Honda Civic, Blue, License: ABC123', 'DL123456789', 'approved', NOW() - INTERVAL '7 days'),
    (runner2_id, false, null, 'Bicycle and public transport', null, 'approved', NOW() - INTERVAL '5 days');

  -- Insert some errand updates
  INSERT INTO errand_updates (errand_id, user_id, message, status_change) VALUES
    ((SELECT id FROM errands WHERE title = 'Prescription Pickup'), runner2_id, 'On my way to CVS pharmacy now', 'in_progress'),
    ((SELECT id FROM errands WHERE title = 'Pet Food Shopping'), runner1_id, 'Completed pickup from PetSmart. Heading to delivery location.', 'completed');

  -- Insert sample reviews
  INSERT INTO reviews (errand_id, reviewer_id, reviewee_id, rating, review_text) VALUES
    ((SELECT id FROM errands WHERE title = 'Pet Food Shopping'), customer1_id, runner1_id, 5, 'Excellent service! Mike was very professional and got exactly the right brand for my dog. Highly recommend!'),
    ((SELECT id FROM errands WHERE title = 'Pet Food Shopping'), runner1_id, customer1_id, 5, 'Great customer! Clear instructions and very polite. Easy pickup and delivery.');
END $$;