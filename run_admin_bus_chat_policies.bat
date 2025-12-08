@echo off
echo ========================================
echo Updating Chat Policies for Admin Bus Conversations
echo ========================================

echo.
echo This will update the RLS policies to allow admins to create and manage bus conversations.
echo.

pause

echo.
echo Running updated chat policies...
echo.

psql -h localhost -p 54322 -U postgres -d postgres -f lib/supabase/supabase_policies.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Chat policies updated successfully!
    echo.
    echo The following admin permissions have been added:
    echo - Admins can create bus conversations
    echo - Admins can update bus conversations
    echo - Admins can delete bus conversations
    echo - Admins can view messages in bus conversations
    echo - Admins can send messages in bus conversations
    echo - Admins can update messages in bus conversations
    echo.
    echo Bus conversations should now work for admin users!
) else (
    echo.
    echo ❌ Error updating chat policies!
    echo Please check the error messages above and try again.
)

echo.
pause
