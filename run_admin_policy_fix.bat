@echo off
echo Running admin policy fixes...
echo.
echo This will fix admin permissions for errands and bus bookings.
echo.
pause
echo Applying policy fixes...
psql -h your-supabase-host -U postgres -d postgres -f fix_admin_policies.sql
echo.
echo Policy fixes completed!
pause
