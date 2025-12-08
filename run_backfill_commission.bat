@echo off
echo ================================================
echo Backfilling Commission Data for Existing Bookings
echo ================================================
echo.
echo This will calculate commission for all existing bookings
echo that have been completed or are active.
echo.
echo Make sure you have already run: run_commission_tracking_setup.bat
echo.
pause

set PGPASSWORD=%SUPABASE_DB_PASSWORD%
psql -h aws-0-eu-central-1.pooler.supabase.com -p 6543 -d postgres -U postgres.%SUPABASE_PROJECT_REF% -f backfill_commission_data.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================
    echo Backfill completed successfully!
    echo Check the output above for statistics.
    echo ================================================
) else (
    echo.
    echo ================================================
    echo ERROR: Backfill failed!
    echo ================================================
)

pause

