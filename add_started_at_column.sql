-- Add missing started_at column to errands table
-- This column is expected by the Flutter app but is missing from the current schema

DO $$
BEGIN
    -- Check if the column already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'errands' AND column_name = 'started_at'
    ) THEN
        -- Add the started_at column
        ALTER TABLE errands ADD COLUMN started_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Column started_at added to errands table';
    ELSE
        RAISE NOTICE 'Column started_at already exists in errands table';
    END IF;
END $$; 