-- Enhanced Runner Documents Migration
-- This script adds structured document storage for runner applications

-- Add new columns to runner_applications table for structured document storage
ALTER TABLE runner_applications 
ADD COLUMN IF NOT EXISTS driver_license_pdf TEXT,
ADD COLUMN IF NOT EXISTS code_of_conduct_pdf TEXT,
ADD COLUMN IF NOT EXISTS vehicle_photos TEXT[],
ADD COLUMN IF NOT EXISTS license_disc_photos TEXT[],
ADD COLUMN IF NOT EXISTS documents_uploaded_at TIMESTAMP WITH TIME ZONE;

-- Update the verification_documents column to be more descriptive
-- Keep the existing column for backward compatibility
COMMENT ON COLUMN runner_applications.verification_documents IS 'Legacy field - use specific document columns instead';

-- Add comments for new columns
COMMENT ON COLUMN runner_applications.driver_license_pdf IS 'URL to uploaded driver license PDF document';
COMMENT ON COLUMN runner_applications.code_of_conduct_pdf IS 'URL to uploaded code of conduct PDF document';
COMMENT ON COLUMN runner_applications.vehicle_photos IS 'Array of URLs to uploaded vehicle photos';
COMMENT ON COLUMN runner_applications.license_disc_photos IS 'Array of URLs to uploaded license disc photos';
COMMENT ON COLUMN runner_applications.documents_uploaded_at IS 'Timestamp when documents were uploaded';

-- Create a function to validate document requirements
CREATE OR REPLACE FUNCTION validate_runner_documents()
RETURNS TRIGGER AS $$
BEGIN
    -- If user has a vehicle, require vehicle-related documents
    IF NEW.has_vehicle = true THEN
        -- Check if all required documents are provided
        IF NEW.driver_license_pdf IS NULL OR NEW.driver_license_pdf = '' THEN
            RAISE EXCEPTION 'Driver license PDF is required for vehicle owners';
        END IF;
        
        IF NEW.code_of_conduct_pdf IS NULL OR NEW.code_of_conduct_pdf = '' THEN
            RAISE EXCEPTION 'Code of conduct PDF is required';
        END IF;
        
        IF NEW.vehicle_photos IS NULL OR array_length(NEW.vehicle_photos, 1) IS NULL THEN
            RAISE EXCEPTION 'At least one vehicle photo is required';
        END IF;
        
        IF NEW.license_disc_photos IS NULL OR array_length(NEW.license_disc_photos, 1) IS NULL THEN
            RAISE EXCEPTION 'At least one license disc photo is required';
        END IF;
    ELSE
        -- For non-vehicle runners, only require basic documents
        IF NEW.code_of_conduct_pdf IS NULL OR NEW.code_of_conduct_pdf = '' THEN
            RAISE EXCEPTION 'Code of conduct PDF is required';
        END IF;
    END IF;
    
    -- Set documents_uploaded_at if not already set
    IF NEW.documents_uploaded_at IS NULL THEN
        NEW.documents_uploaded_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate documents before insert/update
DROP TRIGGER IF EXISTS validate_runner_documents_trigger ON runner_applications;
CREATE TRIGGER validate_runner_documents_trigger
    BEFORE INSERT OR UPDATE ON runner_applications
    FOR EACH ROW
    EXECUTE FUNCTION validate_runner_documents();

-- Create a view for admin verification with all document information
CREATE OR REPLACE VIEW runner_verification_view AS
SELECT 
    ra.id,
    ra.user_id,
    ra.has_vehicle,
    ra.vehicle_type,
    ra.vehicle_details,
    ra.license_number,
    ra.driver_license_pdf,
    ra.code_of_conduct_pdf,
    ra.vehicle_photos,
    ra.license_disc_photos,
    ra.documents_uploaded_at,
    ra.verification_status,
    ra.notes,
    ra.applied_at,
    ra.reviewed_at,
    ra.reviewed_by,
    u.full_name,
    u.email,
    u.phone,
    -- Document status indicators
    CASE 
        WHEN ra.driver_license_pdf IS NOT NULL AND ra.driver_license_pdf != '' THEN true 
        ELSE false 
    END as has_driver_license,
    CASE 
        WHEN ra.code_of_conduct_pdf IS NOT NULL AND ra.code_of_conduct_pdf != '' THEN true 
        ELSE false 
    END as has_code_of_conduct,
    CASE 
        WHEN ra.vehicle_photos IS NOT NULL AND array_length(ra.vehicle_photos, 1) > 0 THEN true 
        ELSE false 
    END as has_vehicle_photos,
    CASE 
        WHEN ra.license_disc_photos IS NOT NULL AND array_length(ra.license_disc_photos, 1) > 0 THEN true 
        ELSE false 
    END as has_license_disc_photos,
    -- Count of documents
    (
        CASE WHEN ra.driver_license_pdf IS NOT NULL AND ra.driver_license_pdf != '' THEN 1 ELSE 0 END +
        CASE WHEN ra.code_of_conduct_pdf IS NOT NULL AND ra.code_of_conduct_pdf != '' THEN 1 ELSE 0 END +
        CASE WHEN ra.vehicle_photos IS NOT NULL THEN array_length(ra.vehicle_photos, 1) ELSE 0 END +
        CASE WHEN ra.license_disc_photos IS NOT NULL THEN array_length(ra.license_disc_photos, 1) ELSE 0 END
    ) as total_documents
FROM runner_applications ra
JOIN users u ON ra.user_id = u.id;

-- Grant permissions for the view
GRANT SELECT ON runner_verification_view TO authenticated;

-- Create RPC function to get runner application with documents
CREATE OR REPLACE FUNCTION get_runner_application_with_documents(user_uuid UUID)
RETURNS TABLE (
    id UUID,
    has_vehicle BOOLEAN,
    vehicle_type TEXT,
    vehicle_details TEXT,
    license_number TEXT,
    driver_license_pdf TEXT,
    code_of_conduct_pdf TEXT,
    vehicle_photos TEXT[],
    license_disc_photos TEXT[],
    documents_uploaded_at TIMESTAMP WITH TIME ZONE,
    verification_status TEXT,
    notes TEXT,
    applied_at TIMESTAMP WITH TIME ZONE,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID,
    has_driver_license BOOLEAN,
    has_code_of_conduct BOOLEAN,
    has_vehicle_photos BOOLEAN,
    has_license_disc_photos BOOLEAN,
    total_documents INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ra.id,
        ra.has_vehicle,
        ra.vehicle_type,
        ra.vehicle_details,
        ra.license_number,
        ra.driver_license_pdf,
        ra.code_of_conduct_pdf,
        ra.vehicle_photos,
        ra.license_disc_photos,
        ra.documents_uploaded_at,
        ra.verification_status,
        ra.notes,
        ra.applied_at,
        ra.reviewed_at,
        ra.reviewed_by,
        CASE 
            WHEN ra.driver_license_pdf IS NOT NULL AND ra.driver_license_pdf != '' THEN true 
            ELSE false 
        END as has_driver_license,
        CASE 
            WHEN ra.code_of_conduct_pdf IS NOT NULL AND ra.code_of_conduct_pdf != '' THEN true 
            ELSE false 
        END as has_code_of_conduct,
        CASE 
            WHEN ra.vehicle_photos IS NOT NULL AND array_length(ra.vehicle_photos, 1) > 0 THEN true 
            ELSE false 
        END as has_vehicle_photos,
        CASE 
            WHEN ra.license_disc_photos IS NOT NULL AND array_length(ra.license_disc_photos, 1) > 0 THEN true 
            ELSE false 
        END as has_license_disc_photos,
        (
            CASE WHEN ra.driver_license_pdf IS NOT NULL AND ra.driver_license_pdf != '' THEN 1 ELSE 0 END +
            CASE WHEN ra.code_of_conduct_pdf IS NOT NULL AND ra.code_of_conduct_pdf != '' THEN 1 ELSE 0 END +
            CASE WHEN ra.vehicle_photos IS NOT NULL THEN array_length(ra.vehicle_photos, 1) ELSE 0 END +
            CASE WHEN ra.license_disc_photos IS NOT NULL THEN array_length(ra.license_disc_photos, 1) ELSE 0 END
        ) as total_documents
    FROM runner_applications ra
    WHERE ra.user_id = user_uuid
    ORDER BY ra.applied_at DESC
    LIMIT 1;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_runner_application_with_documents(UUID) TO authenticated;

-- Create RPC function to update runner application documents
CREATE OR REPLACE FUNCTION update_runner_application_documents(
    user_uuid UUID,
    driver_license_pdf_param TEXT DEFAULT NULL,
    code_of_conduct_pdf_param TEXT DEFAULT NULL,
    vehicle_photos_param TEXT[] DEFAULT NULL,
    license_disc_photos_param TEXT[] DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    application_exists BOOLEAN;
BEGIN
    -- Check if application exists
    SELECT EXISTS(
        SELECT 1 FROM runner_applications 
        WHERE user_id = user_uuid 
        AND verification_status = 'pending'
    ) INTO application_exists;
    
    IF NOT application_exists THEN
        RAISE EXCEPTION 'No pending runner application found for this user';
    END IF;
    
    -- Update the application with new documents
    UPDATE runner_applications 
    SET 
        driver_license_pdf = COALESCE(driver_license_pdf_param, driver_license_pdf),
        code_of_conduct_pdf = COALESCE(code_of_conduct_pdf_param, code_of_conduct_pdf),
        vehicle_photos = COALESCE(vehicle_photos_param, vehicle_photos),
        license_disc_photos = COALESCE(license_disc_photos_param, license_disc_photos),
        documents_uploaded_at = CASE 
            WHEN driver_license_pdf_param IS NOT NULL OR 
                 code_of_conduct_pdf_param IS NOT NULL OR 
                 vehicle_photos_param IS NOT NULL OR 
                 license_disc_photos_param IS NOT NULL 
            THEN NOW() 
            ELSE documents_uploaded_at 
        END,
        updated_at = NOW()
    WHERE user_id = user_uuid 
    AND verification_status = 'pending';
    
    RETURN TRUE;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION update_runner_application_documents(UUID, TEXT, TEXT, TEXT[], TEXT[]) TO authenticated;

-- Update the existing update_runner_application_status function to include document validation
CREATE OR REPLACE FUNCTION update_runner_application_status(
    application_id UUID,
    status TEXT,
    notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    application_record RECORD;
BEGIN
    -- Get the application details
    SELECT * INTO application_record
    FROM runner_applications
    WHERE id = application_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Application not found';
    END IF;
    
    -- Validate documents before approval
    IF status = 'approved' THEN
        -- Check if all required documents are present
        IF application_record.has_vehicle = true THEN
            IF application_record.driver_license_pdf IS NULL OR application_record.driver_license_pdf = '' THEN
                RAISE EXCEPTION 'Cannot approve: Driver license PDF is missing';
            END IF;
            
            IF application_record.vehicle_photos IS NULL OR array_length(application_record.vehicle_photos, 1) IS NULL THEN
                RAISE EXCEPTION 'Cannot approve: Vehicle photos are missing';
            END IF;
            
            IF application_record.license_disc_photos IS NULL OR array_length(application_record.license_disc_photos, 1) IS NULL THEN
                RAISE EXCEPTION 'Cannot approve: License disc photos are missing';
            END IF;
        END IF;
        
        -- Code of conduct is required for all runners
        IF application_record.code_of_conduct_pdf IS NULL OR application_record.code_of_conduct_pdf = '' THEN
            RAISE EXCEPTION 'Cannot approve: Code of conduct PDF is missing';
        END IF;
    END IF;
    
    -- Update the application status
    UPDATE runner_applications 
    SET 
        verification_status = status,
        notes = notes,
        reviewed_at = NOW(),
        reviewed_by = auth.uid(),
        updated_at = NOW()
    WHERE id = application_id;
    
    -- Sync with users table
    UPDATE users 
    SET 
        is_verified = (status = 'approved'),
        has_vehicle = application_record.has_vehicle,
        updated_at = NOW()
    WHERE id = application_record.user_id;
    
    RETURN TRUE;
END;
$$;

-- Grant execute permission on the updated function
GRANT EXECUTE ON FUNCTION update_runner_application_status(UUID, TEXT, TEXT) TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_runner_applications_documents_uploaded 
ON runner_applications(documents_uploaded_at);

-- Add helpful comments
COMMENT ON FUNCTION validate_runner_documents() IS 'Validates that all required documents are uploaded based on vehicle ownership';
COMMENT ON FUNCTION get_runner_application_with_documents(UUID) IS 'Gets runner application with document status indicators';
COMMENT ON FUNCTION update_runner_application_documents(UUID, TEXT, TEXT, TEXT[], TEXT[]) IS 'Updates runner application documents';
COMMENT ON VIEW runner_verification_view IS 'Admin view for runner verification with document status';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Enhanced runner documents migration completed successfully!';
    RAISE NOTICE 'New columns added: driver_license_pdf, code_of_conduct_pdf, vehicle_photos, license_disc_photos';
    RAISE NOTICE 'New functions created: validate_runner_documents, get_runner_application_with_documents, update_runner_application_documents';
    RAISE NOTICE 'New view created: runner_verification_view';
END $$;
