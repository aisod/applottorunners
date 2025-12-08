-- Debug Runner Acceptance Issues
-- This script will help identify the exact errors preventing runners from accepting bookings

-- ==============================================
-- 1. CHECK CURRENT DATABASE STATE
-- ==============================================

-- Check transportation_bookings table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'transportation_bookings' 
ORDER BY ordinal_position;

-- Check contract_bookings table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'contract_bookings' 
ORDER BY ordinal_position;

-- ==============================================
-- 2. CHECK STATUS CONSTRAINTS
-- ==============================================

-- Check transportation_bookings status constraints
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'transportation_bookings'::regclass
AND contype = 'c'
AND pg_get_constraintdef(oid) LIKE '%status%';

-- Check contract_bookings status constraints
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'contract_bookings'::regclass
AND contype = 'c'
AND pg_get_constraintdef(oid) LIKE '%status%';

-- ==============================================
-- 3. CHECK CURRENT STATUS VALUES
-- ==============================================

-- Check current status values in transportation_bookings
SELECT 
    status,
    COUNT(*) as count,
    COUNT(driver_id) as with_driver,
    COUNT(*) - COUNT(driver_id) as without_driver
FROM transportation_bookings 
GROUP BY status
ORDER BY status;

-- Check current status values in contract_bookings
SELECT 
    status,
    COUNT(*) as count,
    COUNT(driver_id) as with_driver,
    COUNT(*) - COUNT(driver_id) as without_driver
FROM contract_bookings 
GROUP BY status
ORDER BY status;

-- ==============================================
-- 4. CHECK RLS POLICIES
-- ==============================================

-- Check transportation_bookings policies
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'transportation_bookings' 
ORDER BY policyname;

-- Check contract_bookings policies
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'contract_bookings' 
ORDER BY policyname;

-- ==============================================
-- 5. TEST ACCEPTANCE SCENARIOS
-- ==============================================

-- Test 1: Try to update transportation booking to 'accepted' status
DO $$
DECLARE
    test_booking_id UUID;
    test_user_id UUID;
    error_message TEXT;
BEGIN
    -- Get a pending transportation booking
    SELECT id INTO test_booking_id 
    FROM transportation_bookings 
    WHERE status = 'pending' AND driver_id IS NULL 
    LIMIT 1;
    
    -- Get a test user (assuming you have users)
    SELECT id INTO test_user_id 
    FROM users 
    WHERE user_type = 'runner' 
    LIMIT 1;
    
    IF test_booking_id IS NOT NULL AND test_user_id IS NOT NULL THEN
        BEGIN
            -- Try to accept the booking
            UPDATE transportation_bookings 
            SET 
                status = 'accepted',
                driver_id = test_user_id,
                updated_at = NOW()
            WHERE id = test_booking_id;
            
            RAISE NOTICE 'SUCCESS: Transportation booking acceptance test passed';
            
            -- Revert the change
            UPDATE transportation_bookings 
            SET 
                status = 'pending',
                driver_id = NULL,
                updated_at = NOW()
            WHERE id = test_booking_id;
            
        EXCEPTION WHEN OTHERS THEN
            error_message := SQLERRM;
            RAISE NOTICE 'ERROR: Transportation booking acceptance failed: %', error_message;
        END;
    ELSE
        RAISE NOTICE 'SKIP: No pending transportation bookings or runners found for testing';
    END IF;
END $$;

-- Test 2: Try to update contract booking to 'accepted' status
DO $$
DECLARE
    test_booking_id UUID;
    test_user_id UUID;
    error_message TEXT;
BEGIN
    -- Get a pending contract booking
    SELECT id INTO test_booking_id 
    FROM contract_bookings 
    WHERE status = 'pending' AND driver_id IS NULL 
    LIMIT 1;
    
    -- Get a test user (assuming you have users)
    SELECT id INTO test_user_id 
    FROM users 
    WHERE user_type = 'runner' 
    LIMIT 1;
    
    IF test_booking_id IS NOT NULL AND test_user_id IS NOT NULL THEN
        BEGIN
            -- Try to accept the contract booking
            UPDATE contract_bookings 
            SET 
                status = 'accepted',
                driver_id = test_user_id,
                updated_at = NOW()
            WHERE id = test_booking_id;
            
            RAISE NOTICE 'SUCCESS: Contract booking acceptance test passed';
            
            -- Revert the change
            UPDATE contract_bookings 
            SET 
                status = 'pending',
                driver_id = NULL,
                updated_at = NOW()
            WHERE id = test_booking_id;
            
        EXCEPTION WHEN OTHERS THEN
            error_message := SQLERRM;
            RAISE NOTICE 'ERROR: Contract booking acceptance failed: %', error_message;
        END;
    ELSE
        RAISE NOTICE 'SKIP: No pending contract bookings or runners found for testing';
    END IF;
END $$;

-- ==============================================
-- 6. CHECK FOR SPECIFIC ERROR CONDITIONS
-- ==============================================

-- Check if 'accepted' status is allowed in constraints
DO $$
DECLARE
    constraint_def TEXT;
BEGIN
    -- Check transportation_bookings constraint
    SELECT pg_get_constraintdef(oid) INTO constraint_def
    FROM pg_constraint 
    WHERE conrelid = 'transportation_bookings'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%status%'
    LIMIT 1;
    
    IF constraint_def IS NOT NULL THEN
        IF constraint_def LIKE '%accepted%' THEN
            RAISE NOTICE 'OK: transportation_bookings constraint allows "accepted" status';
        ELSE
            RAISE NOTICE 'ERROR: transportation_bookings constraint does NOT allow "accepted" status';
            RAISE NOTICE 'Constraint definition: %', constraint_def;
        END IF;
    ELSE
        RAISE NOTICE 'WARNING: No status constraint found on transportation_bookings';
    END IF;
    
    -- Check contract_bookings constraint
    SELECT pg_get_constraintdef(oid) INTO constraint_def
    FROM pg_constraint 
    WHERE conrelid = 'contract_bookings'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%status%'
    LIMIT 1;
    
    IF constraint_def IS NOT NULL THEN
        IF constraint_def LIKE '%accepted%' THEN
            RAISE NOTICE 'OK: contract_bookings constraint allows "accepted" status';
        ELSE
            RAISE NOTICE 'ERROR: contract_bookings constraint does NOT allow "accepted" status';
            RAISE NOTICE 'Constraint definition: %', constraint_def;
        END IF;
    ELSE
        RAISE NOTICE 'WARNING: No status constraint found on contract_bookings';
    END IF;
END $$;

-- ==============================================
-- 7. CHECK RLS POLICY PERMISSIONS
-- ==============================================

-- Test RLS policy for transportation_bookings updates
DO $$
DECLARE
    policy_count INTEGER;
    update_policy_exists BOOLEAN := FALSE;
    accept_policy_exists BOOLEAN := FALSE;
BEGIN
    -- Count total policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'transportation_bookings';
    
    RAISE NOTICE 'transportation_bookings has % RLS policies', policy_count;
    
    -- Check for update policies
    SELECT EXISTS(
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'transportation_bookings' 
        AND cmd = 'UPDATE'
    ) INTO update_policy_exists;
    
    IF update_policy_exists THEN
        RAISE NOTICE 'OK: transportation_bookings has UPDATE policies';
    ELSE
        RAISE NOTICE 'ERROR: transportation_bookings has NO UPDATE policies';
    END IF;
    
    -- Check for policies that allow accepting bookings
    SELECT EXISTS(
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'transportation_bookings' 
        AND cmd = 'UPDATE'
        AND (qual LIKE '%driver_id IS NULL%' OR with_check LIKE '%driver_id%')
    ) INTO accept_policy_exists;
    
    IF accept_policy_exists THEN
        RAISE NOTICE 'OK: transportation_bookings has policies allowing driver assignment';
    ELSE
        RAISE NOTICE 'ERROR: transportation_bookings policies do NOT allow driver assignment';
    END IF;
END $$;

-- ==============================================
-- 8. SUMMARY REPORT
-- ==============================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'RUNNER ACCEPTANCE DEBUG SUMMARY';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Check the output above for:';
    RAISE NOTICE '1. Table structure (driver_id columns)';
    RAISE NOTICE '2. Status constraints (accepted status allowed)';
    RAISE NOTICE '3. Current data state';
    RAISE NOTICE '4. RLS policies (update permissions)';
    RAISE NOTICE '5. Test results (actual acceptance attempts)';
    RAISE NOTICE '6. Error conditions (specific issues found)';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Common issues to look for:';
    RAISE NOTICE '- Missing "accepted" in status constraints';
    RAISE NOTICE '- Missing driver_id column in contract_bookings';
    RAISE NOTICE '- RLS policies blocking updates';
    RAISE NOTICE '- Constraint violations in test attempts';
    RAISE NOTICE '==============================================';
END $$;
