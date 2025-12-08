@echo off
echo ============================================================================
echo FIXING STORAGE POLICIES FOR RUNNER APPLICATION DOCUMENTS
echo ============================================================================
echo.
echo This script will fix the Row Level Security (RLS) policies for the
echo errand-images storage bucket to allow authenticated users to upload
echo runner application documents (driver's license, code of conduct, etc.)
echo.
echo The error "new row violates row-level security policy" will be resolved.
echo.
pause

echo.
echo Running SQL script to fix storage policies...
echo.

psql -h db.your-project.supabase.co -p 5432 -d postgres -U postgres -f fix_storage_policies_simple.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo ✅ STORAGE POLICIES FIXED SUCCESSFULLY!
    echo ============================================================================
    echo.
    echo The errand-images bucket now has proper RLS policies that allow:
    echo - Authenticated users to upload documents
    echo - Public read access to view documents  
    echo - Users to manage their own documents
    echo - Admins to manage all documents
    echo.
    echo Runner application document uploads should now work correctly.
    echo.
) else (
    echo.
    echo ============================================================================
    echo ❌ ERROR FIXING STORAGE POLICIES
    echo ============================================================================
    echo.
    echo There was an error running the SQL script.
    echo Please check your Supabase connection details and try again.
    echo.
    echo You can also run the SQL script manually in your Supabase SQL Editor:
    echo 1. Go to your Supabase Dashboard
    echo 2. Navigate to SQL Editor
    echo 3. Copy and paste the contents of fix_storage_policies_simple.sql
    echo 4. Run the script
    echo.
)

pause
