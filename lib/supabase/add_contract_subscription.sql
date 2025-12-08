-- Add the missing "Contract Subscription" subcategory
-- This was referenced in the original requirements but was missing from the sample data

-- Insert the Contract Subscription subcategory
INSERT INTO service_subcategories (name, description, icon, sort_order) VALUES
('Contract Subscription', 'Long-term business transportation contracts', 'business', 7)
ON CONFLICT (name) DO NOTHING;

-- Update the sort order of existing subcategories to accommodate the new one
UPDATE service_subcategories 
SET sort_order = sort_order + 1 
WHERE sort_order >= 7 AND name != 'Contract Subscription';

-- Set Contract Subscription to sort order 3 (after Shuttle Services)
UPDATE service_subcategories 
SET sort_order = 3 
WHERE name = 'Contract Subscription';

-- Update Ride Sharing and others to shift down
UPDATE service_subcategories 
SET sort_order = 4 
WHERE name = 'Ride Sharing';

UPDATE service_subcategories 
SET sort_order = 5 
WHERE name = 'Airport Transfers';

UPDATE service_subcategories 
SET sort_order = 6 
WHERE name = 'Cargo Transport';

UPDATE service_subcategories 
SET sort_order = 7 
WHERE name = 'Moving Services';

-- Verify the updated subcategories
SELECT id, name, description, icon, sort_order 
FROM service_subcategories 
ORDER BY sort_order;
