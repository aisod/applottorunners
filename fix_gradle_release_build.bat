@echo off
echo ========================================
echo Fixing Gradle Release Build Issues
echo ========================================
echo.

echo Step 1: Cleaning Flutter build...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b %errorlevel%
)
echo.

echo Step 2: Removing corrupted Gradle cache...
if exist "%USERPROFILE%\.gradle\caches\jars-9" (
    echo Deleting jars-9 cache...
    rd /s /q "%USERPROFILE%\.gradle\caches\jars-9"
)
if exist "%USERPROFILE%\.gradle\caches\modules-2" (
    echo Deleting modules-2 cache...
    rd /s /q "%USERPROFILE%\.gradle\caches\modules-2"
)
if exist "%USERPROFILE%\.gradle\caches\transforms-3" (
    echo Deleting transforms-3 cache...
    rd /s /q "%USERPROFILE%\.gradle\caches\transforms-3"
)
echo.

echo Step 3: Cleaning Android build directories...
if exist "android\build" (
    echo Removing android\build...
    rd /s /q "android\build"
)
if exist "android\app\build" (
    echo Removing android\app\build...
    rd /s /q "android\app\build"
)
if exist "build" (
    echo Removing build directory...
    rd /s /q "build"
)
echo.

echo Step 4: Getting Flutter packages...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b %errorlevel%
)
echo.

echo Step 5: Building release APK...
echo This may take several minutes...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Build failed
    echo.
    echo If the build still fails, try:
    echo 1. Restart your computer
    echo 2. Update Flutter: flutter upgrade
    echo 3. Run: flutter doctor -v
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Your APK is located at:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
pause


