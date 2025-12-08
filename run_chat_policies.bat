@echo off
echo ========================================
echo Running Chat RLS Policies Setup
echo ========================================

echo.
echo This script will create comprehensive RLS policies for the chat system.
echo This includes policies for both chat_conversations and chat_messages tables.
echo.

pause

echo.
echo Executing chat policies SQL...
echo.

psql -h localhost -p 54322 -U postgres -d postgres -f create_chat_policies.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Chat policies created successfully!
    echo.
    echo The following policies have been created:
    echo - RLS enabled on chat_conversations and chat_messages tables
    echo - Users can view/create/update conversations they are part of
    echo - Users can send/view messages in their conversations
    echo - Users can update/delete their own messages
    echo - Admin policies for viewing all conversations/messages
    echo - Performance indexes for chat queries
    echo - Helper functions for creating conversations
    echo.
    echo Chat functionality should now work properly!
) else (
    echo.
    echo ❌ Error creating chat policies!
    echo Please check the error messages above and try again.
)

echo.
pause
