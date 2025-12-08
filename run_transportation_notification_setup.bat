@echo off
echo Setting up transportation notification fields...
psql -h localhost -p 54322 -U postgres -d postgres -f add_transportation_notification_fields.sql
echo Transportation notification setup completed!
pause
