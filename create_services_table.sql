-- Create services table with business pricing
CREATE TABLE IF NOT EXISTS services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    business_price DECIMAL(10,2) NOT NULL,
    requires_vehicle BOOLEAN DEFAULT false,
    icon_name TEXT DEFAULT 'task_alt',
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create categories table if it doesn't exist
CREATE TABLE IF NOT EXISTS service_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    icon_name TEXT DEFAULT 'category',
    color TEXT DEFAULT '#2196F3',
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert some basic categories
INSERT INTO service_categories (name, display_name, description, icon_name, color, sort_order) VALUES
('grocery', 'Grocery Shopping', 'Food and household items shopping', 'local_grocery_store', '#4CAF50', 1),
('delivery', 'Package Delivery', 'Package and document delivery services', 'local_shipping', '#2196F3', 2),
('document', 'Document Services', 'Document handling and processing', 'description', '#FF9800', 3),
('shopping', 'Shopping Services', 'General shopping and errands', 'shopping_cart', '#9C27B0', 4),
('cleaning', 'Cleaning Services', 'House and office cleaning', 'cleaning_services', '#00BCD4', 5),
('maintenance', 'Maintenance Services', 'Home and office maintenance', 'build', '#795548', 6),
('other', 'Other Services', 'Miscellaneous services', 'more_horiz', '#607D8B', 7)
ON CONFLICT (name) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_services_category ON services(category);
CREATE INDEX IF NOT EXISTS idx_services_is_active ON services(is_active);
CREATE INDEX IF NOT EXISTS idx_services_created_by ON services(created_by);
CREATE INDEX IF NOT EXISTS idx_service_categories_name ON service_categories(name);
CREATE INDEX IF NOT EXISTS idx_service_categories_is_active ON service_categories(is_active);

-- Apply updated_at trigger to services table
CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_categories_updated_at BEFORE UPDATE ON service_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies for services table
CREATE POLICY "Public can view active services" ON services FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage all services" ON services FOR ALL USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    )
);

-- RLS Policies for service_categories table
CREATE POLICY "Public can view active categories" ON service_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage all categories" ON service_categories FOR ALL USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.user_type = 'admin'
    )
);

-- Insert some sample services
INSERT INTO services (name, description, category, base_price, business_price, requires_vehicle, icon_name) VALUES
('Grocery Shopping', 'Complete grocery shopping service with fresh produce selection', 'grocery', 25.00, 35.00, false, 'local_grocery_store'),
('Package Delivery', 'Fast and secure package delivery service', 'delivery', 30.00, 45.00, true, 'local_shipping'),
('Document Processing', 'Document handling and processing services', 'document', 20.00, 30.00, false, 'description'),
('General Shopping', 'Personal shopping and errand running', 'shopping', 35.00, 50.00, false, 'shopping_cart'),
('House Cleaning', 'Professional house cleaning services', 'cleaning', 50.00, 75.00, false, 'cleaning_services'),
('Home Maintenance', 'Basic home maintenance and repair', 'maintenance', 40.00, 60.00, true, 'build')
ON CONFLICT DO NOTHING;
