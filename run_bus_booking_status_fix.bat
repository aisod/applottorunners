@echo off
echo Running bus booking status constraint fix...
echo.
echo This will update bus booking status values to match transportation orders.
echo.
pause
echo Applying bus booking status constraint fix...
psql -h your-supabase-host -U postgres -d postgres -f fix_bus_booking_status_constraint.sql
echo.
echo Bus booking status constraint fix completed!
pause
