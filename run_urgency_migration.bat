@echo off
echo Running urgency column migration...
echo.

REM Run the SQL script to add urgency column
psql -h your-supabase-host -U postgres -d postgres -f add_urgency_column.sql

echo.
echo Urgency column migration completed!
pause
