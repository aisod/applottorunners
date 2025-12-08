@echo off
echo ================================================
echo Setting up Commission Tracking System
echo ================================================
echo.
echo This will add 33.3%% commission tracking to:
echo - payments table
echo - transportation_bookings table
echo - contract_bookings table
echo - bus_service_bookings table
echo.
echo It will also create:
echo - Commission calculation functions
echo - Automatic commission triggers
echo - Runner earnings summary view
echo - Detailed bookings function
echo.
echo IMPORTANT: Make sure your Supabase credentials are set!
echo Set SUPABASE_PROJECT_REF, SUPABASE_DB_PASSWORD
echo.
pause

set PGPASSWORD=%SUPABASE_DB_PASSWORD%
psql -h aws-0-eu-central-1.pooler.supabase.com -p 6543 -d postgres -U postgres.%SUPABASE_PROJECT_REF% -f add_commission_tracking.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================
    echo Commission tracking setup completed successfully!
    echo ================================================
) else (
    echo.
    echo ================================================
    echo ERROR: Commission tracking setup failed!
    echo ================================================
)

pause

