@echo off
echo Running Enhanced Runner Documents Migration...
echo.

REM Set the database URL (replace with your actual Supabase project URL)
set SUPABASE_URL=https://your-project.supabase.co
set SUPABASE_ANON_KEY=your-anon-key

echo Applying database migration...
psql "%SUPABASE_URL%" -f enhance_runner_documents.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Enhanced runner documents migration completed successfully!
    echo.
    echo New features added:
    echo - Driver license PDF upload
    echo - Code of conduct PDF upload  
    echo - Vehicle photos upload
    echo - License disc photos upload
    echo - Document validation and status tracking
    echo - Enhanced admin verification interface
    echo.
    echo Next steps:
    echo 1. Update your Flutter app dependencies
    echo 2. Test the new document upload functionality
    echo 3. Verify admin can review documents
) else (
    echo.
    echo ❌ Migration failed! Please check the error messages above.
    echo Make sure your database connection is correct.
)

pause
