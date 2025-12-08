@echo off
color 0E
echo ============================================
echo   RUNNER LINKING FIX HELPER
echo ============================================
echo.
echo PROBLEM: 18 runners, but 0 bookings/revenue
echo.
echo ============================================
echo.
echo This is a 2-STEP process:
echo.
echo STEP 1: DIAGNOSE (find the problem)
echo STEP 2: FIX (solve the problem)
echo.
echo ============================================
echo   STEP 1: DIAGNOSE
echo ============================================
echo.
echo 1. Open your web browser
echo 2. Go to: https://supabase.com/dashboard
echo 3. Click on "SQL Editor" (left sidebar)
echo 4. Click "+ New Query"
echo.
echo 5. Open this file in Notepad:
echo    diagnose_runner_linking.sql
echo.
echo 6. Copy ALL the contents (Ctrl+A, then Ctrl+C)
echo 7. Paste into Supabase SQL Editor (Ctrl+V)
echo 8. Click the "Run" button
echo.
echo 9. LOOK AT THE RESULTS - especially:
echo    - How many bookings exist?
echo    - How many have driver_id or runner_id?
echo    - Are most "unassigned"?
echo.
pause
echo.
echo ============================================
echo   STEP 2: FIX
echo ============================================
echo.
echo Now that you know the problem, let's fix it:
echo.
echo 1. Stay in Supabase SQL Editor
echo 2. Click "+ New Query" (to open a new tab)
echo.
echo 3. Open this file in Notepad:
echo    fix_runner_linking.sql
echo.
echo 4. Copy ALL the contents (Ctrl+A, then Ctrl+C)
echo 5. Paste into Supabase SQL Editor (Ctrl+V)
echo 6. Click the "Run" button
echo 7. Wait for green "Success" message
echo.
pause
echo.
echo ============================================
echo   STEP 3: TEST
echo ============================================
echo.
echo 1. Close your Flutter app if it's running
echo 2. Run: flutter run
echo 3. Go to Admin Dashboard
echo 4. Click "Provider Accounting"
echo 5. Pull down to refresh
echo.
echo YOU SHOULD NOW SEE:
echo   - Actual revenue amounts (not $0.00)
echo   - Booking counts
echo   - List of runners with data
echo.
echo ============================================
echo.
echo TROUBLESHOOTING:
echo.
echo If still showing 0:
echo.
echo Option A: Check if bookings are assigned
echo   - Look at diagnostic results from Step 1
echo   - If "unassigned" = high number, bookings need runners
echo.
echo Option B: Manually assign test bookings
echo   - See: FIX_RUNNER_LINKING_NOW.txt
echo   - Section: "ALTERNATIVE: QUICK TEST FIX"
echo.
echo Option C: Review the detailed guide
echo   - Open: RUNNER_LINKING_DIAGNOSIS_AND_FIX.md
echo.
echo ============================================
echo.
echo FILES CREATED FOR YOU:
echo.
echo 1. diagnose_runner_linking.sql  - Step 1 (diagnostic)
echo 2. fix_runner_linking.sql       - Step 2 (fix)
echo 3. FIX_RUNNER_LINKING_NOW.txt   - Quick instructions
echo 4. RUNNER_LINKING_DIAGNOSIS_AND_FIX.md - Full guide
echo 5. run_runner_linking_fix.bat   - This helper script
echo.
echo ============================================
echo.
pause

