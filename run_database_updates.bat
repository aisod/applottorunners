@echo off
echo Running database updates for transportation services...

echo.
echo Step 1: Adding provider_names column to transportation_services table...
echo Please run the following SQL in your Supabase dashboard:
echo.
echo -- Add provider_names array to transportation_services table
echo ALTER TABLE transportation_services ADD COLUMN IF NOT EXISTS provider_names TEXT[] DEFAULT '{}';
echo.
echo CREATE INDEX IF NOT EXISTS idx_transportation_services_provider_names ON transportation_services USING GIN(provider_names);
echo.
echo -- Update existing services to populate provider_names
echo UPDATE transportation_services SET provider_names = (SELECT ARRAY_AGG(sp.name ORDER BY sp.name) FROM service_providers sp WHERE sp.id = ANY(transportation_services.provider_ids)) WHERE provider_ids IS NOT NULL AND array_length(provider_ids, 1) > 0;
echo.

echo Step 2: Update the add_provider_to_service function...
echo Please also run the SQL from update_add_provider_function.sql in your Supabase dashboard
echo.

echo Step 3: Test the changes...
echo After running the SQL, restart your Flutter app and try adding a provider to an existing service.
echo The provider names should now be stored directly in the transportation_services table.

pause
