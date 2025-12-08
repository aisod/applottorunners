-- Cleanup duplicate runner applications
-- This script identifies and removes duplicate applications, keeping only the most recent one

-- First, let's see what duplicate applications exist
SELECT 
    user_id,
    COUNT(*) as application_count,
    array_agg(id ORDER BY created_at DESC) as application_ids,
    array_agg(verification_status ORDER BY created_at DESC) as statuses,
    array_agg(created_at ORDER BY created_at DESC) as created_dates
FROM runner_applications 
GROUP BY user_id 
HAVING COUNT(*) > 1
ORDER BY application_count DESC;

-- Show details of duplicate applications
SELECT 
    ra.id,
    ra.user_id,
    u.full_name,
    u.email,
    ra.verification_status,
    ra.has_vehicle,
    ra.vehicle_type,
    ra.created_at,
    ra.updated_at
FROM runner_applications ra
JOIN users u ON ra.user_id = u.id
WHERE ra.user_id IN (
    SELECT user_id 
    FROM runner_applications 
    GROUP BY user_id 
    HAVING COUNT(*) > 1
)
ORDER BY ra.user_id, ra.created_at DESC;

-- Delete duplicate applications, keeping only the most recent one for each user
WITH ranked_applications AS (
    SELECT 
        id,
        user_id,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) as rn
    FROM runner_applications
)
DELETE FROM runner_applications 
WHERE id IN (
    SELECT id 
    FROM ranked_applications 
    WHERE rn > 1
);

-- Verify cleanup - should show no duplicates
SELECT 
    user_id,
    COUNT(*) as application_count
FROM runner_applications 
GROUP BY user_id 
HAVING COUNT(*) > 1;
