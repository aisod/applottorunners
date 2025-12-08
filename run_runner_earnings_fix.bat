@echo off
echo ========================================
echo Running Runner Earnings View Fix
echo ========================================
echo.

supabase db push --db-url "%SUPABASE_DB_URL%" -f fix_runner_earnings_view_to_use_errands.sql

echo.
echo ========================================
echo Migration Complete!
echo ========================================
pause

