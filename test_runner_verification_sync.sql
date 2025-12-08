-- Test script to verify runner verification synchronization
-- This script tests that both is_verified and verification_status fields are updated correctly

-- Test 1: Create a test runner application
INSERT INTO runner_applications (
    user_id,
    has_vehicle,
    vehicle_type,
    verification_status,
    applied_at
) VALUES (
    '00000000-0000-0000-0000-000000000001', -- Replace with actual test user ID
    true,
    'car',
    'pending',
    NOW()
);

-- Test 2: Check initial state
SELECT 
    u.id,
    u.full_name,
    u.is_verified,
    u.has_vehicle,
    u.vehicle_type,
    ra.verification_status,
    ra.applied_at
FROM users u
LEFT JOIN runner_applications ra ON u.id = ra.user_id
WHERE u.id = '00000000-0000-0000-0000-000000000001';

-- Test 3: Test RPC function for approving application
SELECT update_runner_application_status(
    (SELECT id FROM runner_applications WHERE user_id = '00000000-0000-0000-0000-000000000001' LIMIT 1),
    'approved',
    'Test approval'
);

-- Test 4: Verify both fields are updated
SELECT 
    u.id,
    u.full_name,
    u.is_verified,
    u.has_vehicle,
    u.vehicle_type,
    ra.verification_status,
    ra.reviewed_at,
    ra.notes
FROM users u
LEFT JOIN runner_applications ra ON u.id = ra.user_id
WHERE u.id = '00000000-0000-0000-0000-000000000001';

-- Test 5: Test RPC function for rejecting application
SELECT update_runner_application_status(
    (SELECT id FROM runner_applications WHERE user_id = '00000000-0000-0000-0000-000000000001' LIMIT 1),
    'rejected',
    'Test rejection'
);

-- Test 6: Verify both fields are updated
SELECT 
    u.id,
    u.full_name,
    u.is_verified,
    u.has_vehicle,
    u.vehicle_type,
    ra.verification_status,
    ra.reviewed_at,
    ra.notes
FROM users u
LEFT JOIN runner_applications ra ON u.id = ra.user_id
WHERE u.id = '00000000-0000-0000-0000-000000000001';

-- Test 7: Test direct user verification
SELECT update_user_verification(
    '00000000-0000-0000-0000-000000000001',
    true
);

-- Test 8: Verify both fields are updated
SELECT 
    u.id,
    u.full_name,
    u.is_verified,
    u.has_vehicle,
    u.vehicle_type,
    ra.verification_status,
    ra.reviewed_at,
    ra.notes
FROM users u
LEFT JOIN runner_applications ra ON u.id = ra.user_id
WHERE u.id = '00000000-0000-0000-0000-000000000001';

-- Cleanup: Remove test data
DELETE FROM runner_applications WHERE user_id = '00000000-0000-0000-0000-000000000001';
