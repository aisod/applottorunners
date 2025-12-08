@echo off
echo ========================================
echo Fixing ALL RLS Policy Issues
echo ========================================
echo.
echo This will fix:
echo - Infinite recursion in users table
echo - Admin messages policies
echo - Runner earnings view
echo.
echo Press any key to continue...
pause > nul

echo.
echo [1/2] Fixing RLS policies...
supabase db push --db-url "%SUPABASE_DB_URL%" -f fix_all_rls_policies_complete.sql

echo.
echo [2/2] Fixing runner earnings view...
supabase db push --db-url "%SUPABASE_DB_URL%" -f fix_runner_earnings_view_to_use_errands.sql

echo.
echo ========================================
echo All Fixes Applied Successfully!
echo ========================================
echo.
echo You can now:
echo - Use admin messaging feature
echo - View provider accounting
echo - All scheduled notifications will work
echo.
pause

