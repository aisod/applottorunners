@echo off
echo ========================================
echo Applying Error Fixes
echo ========================================
echo.
echo Fixing:
echo - Infinite recursion in users table RLS policies
echo - Creating is_admin() helper function
echo.

supabase db push --db-url "%SUPABASE_DB_URL%" -f fix_infinite_recursion_and_errors.sql

echo.
echo ========================================
echo Fixes Applied!
echo ========================================
echo.
echo Code fixes (already applied):
echo - Removed vehicle_types relationship from queries
echo - Fixed FetchOptions usage
echo - Fixed Breakpoints import
echo.
pause

