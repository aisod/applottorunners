@echo off
echo Updating RLS policies for delete functionality...
echo.

echo This will update the database policies to allow users to delete their own completed items.
echo.
echo The changes include:
echo 1. Allow only customers to delete their own errands (runners cannot delete errands)
echo 2. Allow users to delete their own completed transportation bookings
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Running SQL update...
psql -h db.your-project.supabase.co -p 5432 -d postgres -U postgres -f update_delete_policies.sql

if %errorlevel% equ 0 (
    echo.
    echo ✅ RLS policies updated successfully!
    echo Customers can delete their own errands, users can delete their own transportation bookings.
) else (
    echo.
    echo ❌ Failed to update RLS policies.
    echo Please check your database connection and try again.
)

echo.
echo Press any key to exit...
pause >nul
