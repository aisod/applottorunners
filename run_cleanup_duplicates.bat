@echo off
echo Cleaning up duplicate runner applications...
echo.

REM Check if psql is available
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: psql command not found. Please install PostgreSQL client tools.
    echo.
    echo You can also run the SQL script manually in your database:
    echo 1. Open your database management tool (pgAdmin, DBeaver, etc.)
    echo 2. Run the cleanup_duplicate_applications.sql file
    echo.
    pause
    exit /b 1
)

echo Running cleanup script...
psql -h localhost -U postgres -d lotto_runners -f cleanup_duplicate_applications.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Cleanup completed successfully!
    echo Duplicate runner applications have been removed.
    echo Only the most recent application for each user is kept.
) else (
    echo.
    echo ❌ Cleanup failed. Please check your database connection.
    echo You may need to update the connection details in this script.
)

echo.
pause
