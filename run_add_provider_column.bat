@echo off
echo Adding selected_provider column to bus_service_bookings table...
echo.

REM Run the SQL script using psql (adjust connection details as needed)
psql -h localhost -U postgres -d lotto_runners -f add_provider_to_bus_bookings.sql

echo.
echo SQL script execution completed.
pause
