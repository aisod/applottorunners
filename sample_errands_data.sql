-- Sample errands data for testing runner functionality
-- Run this in your Supabase SQL editor to add test data

-- First, let's create some sample customer users if they don't exist
-- Note: Replace these UUIDs with actual user IDs from your auth.users table
-- You can get user IDs by running: SELECT id, email FROM auth.users;

-- Sample errands with different statuses
INSERT INTO errands (
    customer_id,
    title,
    description,
    category,
    price_amount,
    time_limit_hours,
    status,
    location_address,
    pickup_address,
    delivery_address,
    special_instructions,
    requires_vehicle,
    created_at
) VALUES 
-- Posted errands (available for runners to accept)
(
    (SELECT id FROM auth.users WHERE email LIKE '%customer%' LIMIT 1),
    'Grocery Shopping at Pick n Pay',
    'Please buy groceries from my shopping list. I need fresh vegetables, milk, bread, and some cleaning supplies. Receipt required.',
    'grocery',
    150.00,
    4,
    'posted',
    'Windhoek West, Pick n Pay Shopping Center',
    'Pick n Pay Windhoek West',
    '123 Independence Avenue, Windhoek',
    'Please call before delivery. Use entrance at the back.',
    false,
    NOW() - INTERVAL '1 hour'
),
(
    (SELECT id FROM auth.users WHERE email LIKE '%customer%' LIMIT 1),
    'Document Delivery to NamPost',
    'Urgent document delivery to main post office. Important legal documents that need to be registered.',
    'document',
    80.00,
    2,
    'posted',
    'Windhoek Central Business District',
    'Legal Chambers, Post Street Mall',
    'NamPost Head Office, Independence Avenue',
    'Documents are in sealed envelope. Handle with care.',
    false,
    NOW() - INTERVAL '30 minutes'
),
(
    (SELECT id FROM auth.users WHERE email LIKE '%business%' LIMIT 1),
    'Furniture Delivery',
    'Pick up office furniture from supplier and deliver to our new office location. Items include desk, chairs, and filing cabinet.',
    'delivery',
    300.00,
    6,
    'posted',
    'Klein Windhoek Industrial Area',
    'Office Furniture Warehouse, Mandume Ndemufayo Ave',
    'New Office Complex, Sam Nujoma Drive',
    'Heavy items - requires vehicle and possibly assistant. Contact manager on arrival.',
    true,
    NOW() - INTERVAL '2 hours'
),
(
    (SELECT id FROM auth.users WHERE email LIKE '%individual%' LIMIT 1),
    'Shopping at Maerua Mall',
    'Shopping for birthday party supplies and gift. Need decorations, cake, and present for 10-year-old.',
    'shopping',
    200.00,
    3,
    'posted',
    'Maerua Mall',
    'Maerua Mall Main Entrance',
    'Hochland Park Residential Area',
    'Gift should be suitable for 10-year-old boy who likes soccer.',
    false,
    NOW() - INTERVAL '45 minutes'
),
(
    (SELECT id FROM auth.users WHERE email LIKE '%customer%' LIMIT 1),
    'Medicine Collection',
    'Collect prescription medicine from pharmacy. Prescription is ready for collection.',
    'other',
    50.00,
    1,
    'posted',
    'Windhoek Central',
    'Central Pharmacy, Independence Avenue',
    'Pioneerspark, 456 Beethoven Street',
    'Patient name: John Smith. ID required for collection.',
    false,
    NOW() - INTERVAL '15 minutes'
),

-- Sample errands with different statuses (for testing runner dashboard)
(
    (SELECT id FROM auth.users WHERE email LIKE '%customer%' LIMIT 1),
    'Accepted Errand - Office Supplies',
    'Purchase office supplies from stationery shop. List includes pens, paper, folders, and printer cartridges.',
    'shopping',
    120.00,
    3,
    'accepted',
    'CBD Windhoek',
    'Stationery World, Post Street Mall',
    'Office Building, Robert Mugabe Avenue',
    'Ask for bulk discount. Receipt required.',
    false,
    NOW() - INTERVAL '3 hours'
),
(
    (SELECT id FROM auth.users WHERE email LIKE '%business%' LIMIT 1),
    'In Progress - Catering Delivery',
    'Pick up catering order for office meeting. 20 lunch boxes with drinks.',
    'delivery',
    400.00,
    2,
    'in_progress',
    'Katutura',
    'Mama Africa Catering, Eveline Street',
    'Corporate Office, Fidel Castro Street',
    'Meeting starts at 1 PM. Time-sensitive delivery.',
    true,
    NOW() - INTERVAL '5 hours'
),
(
    (SELECT id FROM auth.users WHERE email LIKE '%individual%' LIMIT 1),
    'Completed - Hardware Store Run',
    'Bought tools and hardware items for home renovation project.',
    'shopping',
    250.00,
    4,
    'completed',
    'Northern Industrial Area',
    'Builders Warehouse, Northern Industrial',
    'Luxury Hill, 789 Hilltop Drive',
    'Heavy items included. Successfully delivered.',
    true,
    NOW() - INTERVAL '1 day'
);

-- Add some sample runner applications if needed
INSERT INTO runner_applications (
    user_id,
    has_vehicle,
    vehicle_type,
    vehicle_details,
    license_number,
    verification_status,
    applied_at
) VALUES 
(
    (SELECT id FROM auth.users WHERE user_type = 'runner' LIMIT 1),
    true,
    'sedan',
    'Toyota Corolla 2018 - Silver',
    'N12345WH',
    'approved',
    NOW() - INTERVAL '1 week'
),
(
    (SELECT id FROM auth.users WHERE user_type = 'runner' OFFSET 1 LIMIT 1),
    false,
    null,
    'On foot and public transport',
    null,
    'approved',
    NOW() - INTERVAL '3 days'
);

-- Update some errands to have runner assignments (for testing My Errands functionality)
-- You'll need to replace the runner_id with actual runner user IDs
UPDATE errands 
SET 
    runner_id = (SELECT id FROM auth.users WHERE user_type = 'runner' LIMIT 1),
    accepted_at = NOW() - INTERVAL '2 hours'
WHERE status = 'accepted';

UPDATE errands 
SET 
    runner_id = (SELECT id FROM auth.users WHERE user_type = 'runner' LIMIT 1),
    accepted_at = NOW() - INTERVAL '4 hours'
WHERE status = 'in_progress';

UPDATE errands 
SET 
    runner_id = (SELECT id FROM auth.users WHERE user_type = 'runner' LIMIT 1),
    accepted_at = NOW() - INTERVAL '1 day',
    completed_at = NOW() - INTERVAL '12 hours'
WHERE status = 'completed';

-- Update runner profiles to have vehicle information
UPDATE users 
SET has_vehicle = true 
WHERE user_type = 'runner' 
AND id = (SELECT id FROM auth.users WHERE user_type = 'runner' LIMIT 1);

UPDATE users 
SET has_vehicle = false 
WHERE user_type = 'runner' 
AND id = (SELECT id FROM auth.users WHERE user_type = 'runner' OFFSET 1 LIMIT 1); 