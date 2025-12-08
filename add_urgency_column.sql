-- Add urgency column to errands table
-- This column will store the processing urgency level for registration services

ALTER TABLE errands 
ADD COLUMN urgency VARCHAR(20) CHECK (urgency IN ('standard', 'express'));

-- Add a comment to document the column
COMMENT ON COLUMN errands.urgency IS 'Processing urgency level: standard or express';

-- Update existing records to have default urgency
UPDATE errands SET urgency = 'standard' WHERE urgency IS NULL;

-- Make the column NOT NULL after setting default values
ALTER TABLE errands ALTER COLUMN urgency SET NOT NULL;
