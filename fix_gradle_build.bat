@echo off
echo Fixing Gradle Build Issues...
echo.

REM Set JAVA_HOME to Android Studio's JBR
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
echo Setting JAVA_HOME to: %JAVA_HOME%

REM Verify Java installation
if not exist "%JAVA_HOME%\bin\java.exe" (
    echo ERROR: Java not found at %JAVA_HOME%
    echo Please check your Android Studio installation
    pause
    exit /b 1
)

echo Java found at: %JAVA_HOME%
echo.

REM Stop all Gradle daemons
echo Stopping Gradle daemons...
cd android
gradlew --stop 2>nul
cd ..
echo.

REM Clean Flutter
echo Cleaning Flutter build cache...
flutter clean
echo.

REM Clean Android build
echo Cleaning Android build cache...
cd android
gradlew clean 2>nul
cd ..
echo.

REM Clean Gradle cache (force stop daemons first)
echo Cleaning Gradle cache...
taskkill /f /im java.exe 2>nul
timeout /t 2 /nobreak >nul
rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
echo.

REM Get Flutter dependencies
echo Getting Flutter dependencies...
flutter pub get
echo.

REM Try to build the app
echo Building Android app...
flutter build apk --debug
echo.

if %errorlevel% equ 0 (
    echo SUCCESS: Build completed successfully!
) else (
    echo Build failed. Please check the error messages above.
    echo.
    echo Additional troubleshooting steps:
    echo 1. Make sure Android Studio is closed
    echo 2. Restart your computer to clear any locked files
    echo 3. Check that your Flutter and Android SDK are up to date
)

pause 