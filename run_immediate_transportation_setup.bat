@echo off
echo Setting up immediate transportation system...

echo.
echo 1. Adding is_immediate column to transportation_bookings table...
psql -h your-supabase-host -U postgres -d postgres -f add_immediate_booking_column.sql

echo.
echo 2. Setting up auto-delete triggers...
psql -h your-supabase-host -U postgres -d postgres -f immediate_transportation_auto_delete.sql

echo.
echo 3. Testing the setup...
psql -h your-supabase-host -U postgres -d postgres -f test_immediate_transportation_deletion.sql

echo.
echo 4. Manual cleanup test...
psql -h your-supabase-host -U postgres -d postgres -f manual_immediate_transportation_cleanup.sql

echo.
echo Immediate transportation setup complete!
echo.
echo Next steps:
echo 1. Update your Flutter app to include the new services
echo 2. Test the immediate transportation flow
echo 3. Monitor the immediate_transportation_bookings_monitor view
echo.
pause

