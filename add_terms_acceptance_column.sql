-- Add Terms and Conditions Acceptance Tracking
-- Run this script in your Supabase SQL Editor

-- Add columns to track terms acceptance
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_terms_accepted ON users(terms_accepted);

-- Update existing users to have terms_accepted = false (they need to accept)
UPDATE users 
SET terms_accepted = false 
WHERE terms_accepted IS NULL;

