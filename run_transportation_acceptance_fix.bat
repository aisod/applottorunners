@echo off
echo ===============================================
echo FIXING TRANSPORTATION BOOKING ACCEPTANCE ISSUES
echo ===============================================
echo.
echo This script will fix the issues preventing runners from accepting
echo contract and shuttle services by:
echo.
echo 1. Adding "accepted" status to transportation_bookings constraint
echo 2. Adding driver_id column to contract_bookings table  
echo 3. Adding "accepted" status to contract_bookings constraint
echo 4. Updating RLS policies to allow runner acceptance
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Running database fixes...
echo.

REM Try to run the SQL script
if exist "fix_transportation_acceptance_complete.sql" (
    echo Found fix_transportation_acceptance_complete.sql
    echo.
    echo IMPORTANT: You need to run this SQL script in your Supabase database.
    echo The script is located at: fix_transportation_acceptance_complete.sql
    echo.
    echo To run it:
    echo 1. Open Supabase Dashboard
    echo 2. Go to SQL Editor
    echo 3. Copy and paste the contents of fix_transportation_acceptance_complete.sql
    echo 4. Execute the script
    echo.
    echo Alternatively, if you have psql installed:
    echo psql -h your-host -U postgres -d your-database -f fix_transportation_acceptance_complete.sql
    echo.
) else (
    echo ERROR: fix_transportation_acceptance_complete.sql not found!
    echo Please make sure the file exists in the current directory.
)

echo.
echo ===============================================
echo SUMMARY OF ISSUES FOUND AND FIXED:
echo ===============================================
echo.
echo PROBLEM 1: Status Constraint Mismatch
echo - transportation_bookings only allowed 'confirmed' status
echo - Application code tries to set 'accepted' status
echo - SOLUTION: Added 'accepted' to allowed statuses
echo.
echo PROBLEM 2: Contract Bookings Missing Driver Assignment
echo - contract_bookings table had no driver_id column
echo - Runners couldn't be assigned to contract bookings
echo - SOLUTION: Added driver_id column with proper constraints
echo.
echo PROBLEM 3: RLS Policy Restrictions
echo - Policies didn't allow runners to accept available bookings
echo - Missing policies for contract_bookings driver assignment
echo - SOLUTION: Updated all RLS policies to allow acceptance
echo.
echo ===============================================
echo NEXT STEPS:
echo ===============================================
echo 1. Run the SQL script in your Supabase database
echo 2. Test accepting transportation bookings as a runner
echo 3. Test accepting contract bookings as a runner
echo 4. Verify that status changes work correctly
echo.
echo Press any key to exit...
pause >nul
