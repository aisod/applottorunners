@echo off
echo ============================================
echo   Accounting View Fix Runner
echo ============================================
echo.
echo This script will help you fix the provider accounting view.
echo.
echo Since psql is not available, please follow these steps:
echo.
echo 1. Go to your Supabase Dashboard: https://supabase.com/dashboard
echo 2. Select your project
echo 3. Go to SQL Editor (left sidebar)
echo 4. Click "New Query"
echo 5. Copy and paste the contents of fix_accounting_view.sql
echo 6. Click "Run" or press Ctrl+Enter
echo.
echo The SQL will:
echo   - Drop and recreate the runner_earnings_summary view
echo   - Include ALL booking statuses (pending, accepted, active, etc.)
echo   - Properly aggregate bookings by type
echo   - Create the get_runner_detailed_bookings function
echo.
echo After running the SQL, restart your Flutter app and refresh
echo the Provider Accounting page.
echo.
pause

