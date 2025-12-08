@echo off
echo Running contract status constraint fix...
echo.

REM Set your database connection details
set PGHOST=your_host
set PGPORT=5432
set PGDATABASE=your_database
set PGUSER=your_username
set PGPASSWORD=your_password

REM Run the SQL script
psql -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -U %PGUSER% -f fix_contract_status_constraint.sql

echo.
echo Contract status constraint fix completed!
pause
