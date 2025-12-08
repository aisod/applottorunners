-- Enhanced errands table to support category-specific fields
-- First, add new columns to existing errands table
ALTER TABLE errands 
ADD COLUMN IF NOT EXISTS service_type TEXT,
ADD COLUMN IF NOT EXISTS queue_type TEXT CHECK (queue_type IN ('now', 'scheduled')),
ADD COLUMN IF NOT EXISTS customer_arrival_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS stores JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS products JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS pricing_modifiers JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS calculated_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS location_latitude DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS location_longitude DECIMAL(11,8),
ADD COLUMN IF NOT EXISTS pickup_latitude DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS pickup_longitude DECIMAL(11,8),
ADD COLUMN IF NOT EXISTS delivery_latitude DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS delivery_longitude DECIMAL(11,8),
ADD COLUMN IF NOT EXISTS pdf_urls JSONB DEFAULT '[]';

-- Update category constraint to include new service types
ALTER TABLE errands DROP CONSTRAINT IF EXISTS errands_category_check;
ALTER TABLE errands ADD CONSTRAINT errands_category_check 
CHECK (category IN (
    'queue_sitting', 
    'license_discs', 
    'shopping', 
    'document_services', 
    'elderly_services',
    'grocery', 
    'delivery', 
    'document', 
    'cleaning', 
    'maintenance', 
    'other'
));

-- Add service_type constraint for document services
ALTER TABLE errands ADD CONSTRAINT errands_service_type_check 
CHECK (
    (category != 'document_services') OR 
    (category = 'document_services' AND service_type IN ('certify', 'copies', 'other'))
);

-- Create indexes for new fields
CREATE INDEX IF NOT EXISTS idx_errands_queue_type ON errands(queue_type);
CREATE INDEX IF NOT EXISTS idx_errands_service_type ON errands(service_type);
CREATE INDEX IF NOT EXISTS idx_errands_location_lat_lng ON errands(location_latitude, location_longitude);
CREATE INDEX IF NOT EXISTS idx_errands_pickup_lat_lng ON errands(pickup_latitude, pickup_longitude);
CREATE INDEX IF NOT EXISTS idx_errands_delivery_lat_lng ON errands(delivery_latitude, delivery_longitude);

-- Add new service types with specific pricing rules
INSERT INTO services (name, description, category, base_price, business_price, requires_vehicle, icon_name) VALUES
('Queue Sitting - Scheduled', 'Professional queue waiting service with advance booking', 'queue_sitting', 50.00, 70.00, false, 'people_alt'),
('Queue Sitting - Now', 'Immediate queue waiting service (additional charge applies)', 'queue_sitting', 80.00, 100.00, false, 'people_alt'),
('License Disc Collection', 'Vehicle license disc collection and delivery', 'license_discs', 40.00, 55.00, true, 'directions_car'),
('Package Delivery - Standard', 'Fast and secure package delivery service', 'delivery', 30.00, 45.00, true, 'local_shipping'),
('Package Delivery - Urgent', 'Urgent package delivery service', 'delivery', 50.00, 70.00, true, 'local_shipping'),
('Package Delivery - Express', 'Express package delivery service', 'delivery', 80.00, 120.00, true, 'local_shipping'),
('Document Certification', 'Professional document certification service', 'document_services', 25.00, 35.00, false, 'verified'),
('Document Copies', 'Document copying and notarization', 'document_services', 15.00, 25.00, false, 'content_copy'),
('General Documents', 'Other document-related services', 'document_services', 30.00, 45.00, false, 'description'),
('Elderly Assistance', 'Specialized assistance and companionship for elderly', 'elderly_services', 60.00, 80.00, false, 'elderly'),
('Personal Shopping', 'Store-to-store shopping with product selection', 'shopping', 45.00, 65.00, true, 'shopping_cart')
ON CONFLICT DO NOTHING;

-- Create function to calculate dynamic pricing
CREATE OR REPLACE FUNCTION calculate_errand_pricing(
    errand_category TEXT,
    base_price DECIMAL(10,2),
    queue_type TEXT DEFAULT NULL,
    delivery_urgency TEXT DEFAULT NULL,
    package_size TEXT DEFAULT NULL,
    is_fragile BOOLEAN DEFAULT FALSE,
    user_type TEXT DEFAULT 'individual'
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    final_price DECIMAL(10,2);
    queue_surcharge DECIMAL(10,2) := 30.00;
    urgent_surcharge DECIMAL(10,2) := 20.00;
    express_surcharge DECIMAL(10,2) := 50.00;
    medium_size_fee DECIMAL(10,2) := 10.00;
    large_size_fee DECIMAL(10,2) := 25.00;
    fragile_fee DECIMAL(10,2) := 15.00;
BEGIN
    final_price := base_price;
    
    -- Apply user type multiplier
    IF user_type = 'business' THEN
        final_price := final_price * 1.4; -- 40% increase for business users
    END IF;
    
    -- Apply queue sitting "now" surcharge
    IF errand_category = 'queue_sitting' AND queue_type = 'now' THEN
        final_price := final_price + queue_surcharge;
    END IF;
    
    -- Apply delivery urgency surcharges
    IF errand_category = 'delivery' THEN
        IF delivery_urgency = 'urgent' THEN
            final_price := final_price + urgent_surcharge;
        ELSIF delivery_urgency = 'express' THEN
            final_price := final_price + express_surcharge;
        END IF;
        
        -- Apply package size fees
        IF package_size = 'medium' THEN
            final_price := final_price + medium_size_fee;
        ELSIF package_size = 'large' THEN
            final_price := final_price + large_size_fee;
        END IF;
        
        -- Apply fragile item fee
        IF is_fragile THEN
            final_price := final_price + fragile_fee;
        END IF;
    END IF;
    
    RETURN final_price;
END;
$$ LANGUAGE plpgsql;
