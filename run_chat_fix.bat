@echo off
echo ========================================
echo Fixing Chat RLS Policies
echo ========================================

echo.
echo This will fix the chat message sending issue by creating proper RLS policies.
echo.

pause

echo.
echo Running chat RLS fix...
echo.

psql -h localhost -p 54322 -U postgres -d postgres -f fix_chat_rls_policies.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Chat RLS policies fixed successfully!
    echo.
    echo Chat messages should now work properly.
    echo Try sending a message again.
) else (
    echo.
    echo ❌ Error fixing chat policies!
    echo Please check the error messages above.
)

echo.
pause
