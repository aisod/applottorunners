@echo off
echo ========================================
echo Lotto Runners - Feedback Table Setup
echo ========================================
echo.
echo This script will create the feedback table and RLS policies.
echo.
echo Make sure you have:
echo 1. Supabase CLI installed
echo 2. Your Supabase project configured
echo 3. Database connection credentials
echo.
pause

echo.
echo Creating feedback table...
echo.

REM You can run this SQL file directly in your Supabase SQL editor
REM or use psql if you have direct database access
echo To apply this migration:
echo 1. Open your Supabase Dashboard
echo 2. Go to SQL Editor
echo 3. Copy and paste the contents of create_feedback_table.sql
echo 4. Run the SQL script
echo.
echo Alternatively, if you have psql configured:
echo psql -h [your-host] -U [your-user] -d [your-database] -f create_feedback_table.sql
echo.
pause

