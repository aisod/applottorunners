@echo off
REM Build release APK using JDK 21 (avoids jdk-25 invalid javaHome error)
set "JAVA_HOME=C:\Program Files\Java\jdk-21"
if not exist "%JAVA_HOME%\bin\java.exe" (
    echo ERROR: JDK 21 not found at %JAVA_HOME%
    echo Install JDK 21 or edit this script to point to your Java 21 path.
    exit /b 1
)
echo Using Java: %JAVA_HOME%
cd /d "%~dp0"

REM Stop Gradle daemon so it picks up correct Java
cd android
call gradlew.bat --stop 2>nul
cd ..

flutter build apk
exit /b %errorlevel%
