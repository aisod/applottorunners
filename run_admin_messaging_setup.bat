@echo off
echo ========================================
echo Setting Up Admin Messaging System
echo and Accounting RLS Policies
echo ========================================
echo.

supabase db push --db-url "%SUPABASE_DB_URL%" -f add_admin_messaging_and_accounting_rls.sql

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Features added:
echo - Admin messaging to runners
echo - Broadcast messaging to all runners
echo - RLS policies for provider accounting
echo.
pause

