@echo off
echo Running verified runner vehicle update fix...
psql -h localhost -p 5432 -U postgres -d lotto_runners -f fix_verified_runner_vehicle_update_simple.sql
echo Fix completed!
pause
