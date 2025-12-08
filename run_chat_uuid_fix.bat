@echo off
echo ========================================
echo Fixing Chat UUID Columns for Bus and Contract
echo ========================================

echo.
echo This will add UUID columns for bus and contract bookings to the chat system.
echo This fixes the chat conversation creation errors.
echo.

pause

echo.
echo Running chat UUID columns migration...
echo.

psql -h localhost -p 54322 -U postgres -d postgres -f add_chat_uuid_columns.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Chat UUID columns added successfully!
    echo.
    echo The following changes have been made:
    echo - Added bus_service_booking_id column to chat_conversations
    echo - Added contract_booking_id column to chat_conversations
    echo - Updated conversation_type enum to include 'bus' and 'contract'
    echo - Updated constraints to ensure proper references
    echo - Added helper functions for bus and contract conversations
    echo - Updated RLS policies for new conversation types
    echo.
    echo Chat functionality should now work for all booking types!
    echo Try creating bus or contract conversations again.
) else (
    echo.
    echo ❌ Error adding chat UUID columns!
    echo Please check the error messages above and try again.
)

echo.
pause
