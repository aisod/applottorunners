-- Add is_immediate column to errands table for immediate errand requests
ALTER TABLE errands ADD COLUMN IF NOT EXISTS is_immediate BOOLEAN DEFAULT false;

-- Add index for better query performance on immediate errands
CREATE INDEX IF NOT EXISTS idx_errands_is_immediate ON errands(is_immediate);
CREATE INDEX IF NOT EXISTS idx_errands_status_immediate ON errands(status, is_immediate);

-- Update RLS policies to allow runners to see immediate errands
-- This will be handled by existing policies that show posted errands to runners

