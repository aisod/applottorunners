@echo off
echo ========================================
echo Running Chat RLS Policies Update
echo ========================================

echo.
echo This script will apply the chat RLS policies from supabase_policies.sql
echo to fix the chat message sending issue.
echo.

pause

echo.
echo Executing chat policies from supabase_policies.sql...
echo.

psql -h localhost -p 54322 -U postgres -d postgres -f lib/supabase/supabase_policies.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Chat policies applied successfully!
    echo.
    echo The following policies have been created:
    echo - RLS enabled on chat_conversations and chat_messages tables
    echo - Users can view/create/update conversations they are part of
    echo - Users can send/view messages in their conversations
    echo - Users can update/delete their own messages
    echo - Admin policies for viewing all conversations/messages
    echo.
    echo Chat functionality should now work properly!
    echo Try sending a message again.
) else (
    echo.
    echo ❌ Error applying chat policies!
    echo Please check the error messages above and try again.
)

echo.
pause
