-- Migration to add service subcategory support to vehicle types
-- This replaces the hardcoded vehicle_class field with a many-to-many relationship

-- 1. Create junction table for vehicle types and service subcategories
CREATE TABLE IF NOT EXISTS vehicle_type_subcategories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type_id UUID REFERENCES vehicle_types(id) ON DELETE CASCADE NOT NULL,
  subcategory_id UUID REFERENCES service_subcategories(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vehicle_type_id, subcategory_id)
);

-- 2. Add index for performance
CREATE INDEX IF NOT EXISTS idx_vehicle_type_subcategories_vehicle_type 
ON vehicle_type_subcategories(vehicle_type_id);

CREATE INDEX IF NOT EXISTS idx_vehicle_type_subcategories_subcategory 
ON vehicle_type_subcategories(subcategory_id);

-- 3. Handle existing vehicle_class constraint and add service_subcategory_ids column
-- First, make vehicle_class nullable if it exists and has NOT NULL constraint
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vehicle_types' 
        AND column_name = 'vehicle_class'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE vehicle_types ALTER COLUMN vehicle_class DROP NOT NULL;
    END IF;
END $$;

-- Add service_subcategory_ids column to vehicle_types table for easier access
ALTER TABLE vehicle_types 
ADD COLUMN IF NOT EXISTS service_subcategory_ids UUID[] DEFAULT '{}';

-- 4. Create a function to sync the array with the junction table
CREATE OR REPLACE FUNCTION sync_vehicle_subcategory_ids()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the array when junction table changes
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE vehicle_types 
    SET service_subcategory_ids = (
      SELECT array_agg(subcategory_id) 
      FROM vehicle_type_subcategories 
      WHERE vehicle_type_id = NEW.vehicle_type_id
    )
    WHERE id = NEW.vehicle_type_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE vehicle_types 
    SET service_subcategory_ids = (
      SELECT array_agg(subcategory_id) 
      FROM vehicle_type_subcategories 
      WHERE vehicle_type_id = OLD.vehicle_type_id
    )
    WHERE id = OLD.vehicle_type_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. Create triggers to keep the array in sync
CREATE TRIGGER trigger_sync_vehicle_subcategory_ids
  AFTER INSERT OR UPDATE OR DELETE ON vehicle_type_subcategories
  FOR EACH ROW EXECUTE FUNCTION sync_vehicle_subcategory_ids();

-- 6. Create a function to update vehicle subcategories
CREATE OR REPLACE FUNCTION update_vehicle_subcategories(
  p_vehicle_type_id UUID,
  p_subcategory_ids UUID[]
)
RETURNS VOID AS $$
BEGIN
  -- Remove existing relationships
  DELETE FROM vehicle_type_subcategories 
  WHERE vehicle_type_id = p_vehicle_type_id;
  
  -- Add new relationships
  IF p_subcategory_ids IS NOT NULL AND array_length(p_subcategory_ids, 1) > 0 THEN
    INSERT INTO vehicle_type_subcategories (vehicle_type_id, subcategory_id)
    SELECT p_vehicle_type_id, unnest(p_subcategory_ids);
  END IF;
  
  -- Update the array column
  UPDATE vehicle_types 
  SET service_subcategory_ids = p_subcategory_ids
  WHERE id = p_vehicle_type_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Create a view for easier querying
CREATE OR REPLACE VIEW vehicle_types_with_subcategories AS
SELECT 
  vt.*,
  array_agg(vts.subcategory_id) as subcategory_ids,
  array_agg(ss.name) as subcategory_names
FROM vehicle_types vt
LEFT JOIN vehicle_type_subcategories vts ON vt.id = vts.vehicle_type_id
LEFT JOIN service_subcategories ss ON vts.subcategory_id = ss.id
GROUP BY vt.id;

-- 8. Optionally remove the old vehicle_class column (uncomment if you want to remove it)
-- Note: This will permanently delete the old classification data
-- ALTER TABLE vehicle_types DROP COLUMN IF EXISTS vehicle_class;

-- 9. Verify the migration
SELECT 
  'Migration completed successfully' as status,
  (SELECT COUNT(*) FROM vehicle_type_subcategories) as junction_records,
  (SELECT COUNT(*) FROM vehicle_types WHERE service_subcategory_ids IS NOT NULL) as vehicles_with_subcategories;
