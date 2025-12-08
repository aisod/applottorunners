@echo off
echo Running provider diagnosis and fix script...
echo.

REM Try to run with Supabase CLI if available
supabase db reset --db-url "postgresql://postgres:password@localhost:54322/postgres" 2>nul
if %errorlevel% equ 0 (
    echo Using Supabase CLI...
    supabase db reset --db-url "postgresql://postgres:password@localhost:54322/postgres"
    goto :end
)

REM Try to run with psql if available
psql -h localhost -U postgres -d lotto_runners -f diagnose_and_fix_providers.sql 2>nul
if %errorlevel% equ 0 (
    echo Using psql...
    psql -h localhost -U postgres -d lotto_runners -f diagnose_and_fix_providers.sql
    goto :end
)

echo.
echo ERROR: Neither Supabase CLI nor psql found in PATH
echo.
echo Please run the SQL script manually using one of these methods:
echo.
echo 1. Using Supabase Dashboard:
echo    - Go to https://supabase.com/dashboard
echo    - Select your project
echo    - Go to SQL Editor
echo    - Copy and paste the contents of diagnose_and_fix_providers.sql
echo    - Click Run
echo.
echo 2. Using psql (if PostgreSQL is installed):
echo    psql -h localhost -U postgres -d lotto_runners -f diagnose_and_fix_providers.sql
echo.
echo 3. Using Supabase CLI (if installed):
echo    supabase db reset --db-url "postgresql://postgres:password@localhost:54322/postgres"
echo.
pause

:end
echo.
echo Script execution completed.
pause
