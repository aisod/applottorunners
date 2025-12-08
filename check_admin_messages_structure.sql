-- Check the current structure of admin_messages table
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns 
WHERE table_name = 'admin_messages'
ORDER BY ordinal_position;

-- Check if there are any broadcast messages
SELECT id, recipient_id, sent_to_all_runners, subject, created_at
FROM admin_messages
WHERE sent_to_all_runners = TRUE
ORDER BY created_at DESC
LIMIT 10;

-- Count messages by type
SELECT 
    sent_to_all_runners,
    COUNT(*) as message_count,
    COUNT(DISTINCT subject) as unique_subjects
FROM admin_messages
GROUP BY sent_to_all_runners;

