@echo off
echo ================================================
echo Diagnosing Commission Accounting Issues
echo ================================================
echo.
echo This will check your database to see why
echo the provider accounting might show 0.
echo.
pause

set PGPASSWORD=%SUPABASE_DB_PASSWORD%
psql -h aws-0-eu-central-1.pooler.supabase.com -p 6543 -d postgres -U postgres.%SUPABASE_PROJECT_REF% -f diagnose_commission_issue.sql

echo.
echo ================================================
echo Diagnostic complete!
echo Review the output above to identify the issue.
echo ================================================
pause

