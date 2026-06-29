# Capture Google Play phone screenshots on Android emulator (adb screencap).
#
# Usage (from project root):
#   .\tools\capture_play_screenshots.ps1
#
# With test account (captures home, orders, profile, etc.):
#   $env:SCREENSHOT_EMAIL = "your-test@email.com"
#   $env:SCREENSHOT_PASSWORD = "your-password"
#   .\tools\capture_play_screenshots.ps1
#
# Output (after resize): store/google-play/screenshots/phone/*.png (1080x1920)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$adb = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
$emu = Join-Path $env:LOCALAPPDATA "Android\sdk\emulator\emulator.exe"
$AvdName = "Medium_Phone_API_36.1"
$Package = "com.mycompany.LottoRunners"
$Activity = "$Package/.MainActivity"
$screenshotsDir = Join-Path $Root "screenshots"

if (-not (Test-Path $adb)) {
    Write-Error "adb not found at $adb. Install Android SDK platform-tools."
}

function Get-ReadyDevices {
    & $adb devices | Select-String "\sdevice$"
}

function Select-EmulatorDevice {
    foreach ($line in Get-ReadyDevices) {
        $id = ($line.Line -split "\s+")[0]
        if ($id -match "^emulator-") { return $id }
    }
    return $null
}

function Wait-ForEmulator {
    param([string]$Serial)
    $deadline = (Get-Date).AddMinutes(5)
    do {
        $boot = & $adb -s $Serial shell getprop sys.boot_completed 2>$null
        if ($boot -match "1") { return }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)
    Write-Error "Emulator did not finish booting within 5 minutes."
}

function Get-ScreenSize {
    param([string]$Serial)
    $out = & $adb -s $Serial shell wm size
    if ($out -match "(\d+)x(\d+)") {
        return [int]$Matches[1], [int]$Matches[2]
    }
    return 1080, 2400
}

function Invoke-TapPercent {
    param([string]$Serial, [double]$xPct, [double]$yPct)
    $w, $h = Get-ScreenSize $Serial
    $x = [int][Math]::Round($w * $xPct)
    $y = [int][Math]::Round($h * $yPct)
    & $adb -s $Serial shell input tap $x $y | Out-Null
}

function Save-AdbScreenshot {
    param([string]$Serial, [string]$Name)
    $remote = "/sdcard/$Name.png"
    $local = Join-Path $screenshotsDir "$Name.png"
    & $adb -s $Serial shell screencap $remote | Out-Null
    & $adb -s $Serial pull $remote $local | Out-Null
    & $adb -s $Serial shell rm $remote 2>$null | Out-Null
    if (-not (Test-Path $local)) {
        Write-Error "Failed to capture screenshot: $Name"
    }
    Write-Host "Captured $Name"
}

function Send-AdbText {
    param([string]$Serial, [string]$Text)
    # adb input text: spaces = %s, @ = %40
    $escaped = $Text -replace ' ', '%s' -replace '@', '%40'
    & $adb -s $Serial shell input text $escaped | Out-Null
}

function Clear-ActiveField {
    param([string]$Serial)
    for ($i = 0; $i -lt 48; $i++) {
        & $adb -s $Serial shell input keyevent 67 | Out-Null
    }
}

function Type-InField {
    param([string]$Serial, [double]$xPct, [double]$yPct, [string]$Text)
    Invoke-TapPercent $Serial $xPct $yPct
    Start-Sleep -Milliseconds 700
    Invoke-TapPercent $Serial $xPct $yPct
    Start-Sleep -Milliseconds 400
    Clear-ActiveField $Serial
    Send-AdbText $Serial $Text
    Start-Sleep -Milliseconds 400
}

function Sign-InViaAdb {
    param([string]$Serial, [string]$Email, [string]$Password)
    Type-InField $Serial 0.50 0.415 $Email
    Type-InField $Serial 0.50 0.485 $Password
    Invoke-TapPercent $Serial 0.50 0.575
    Start-Sleep -Seconds 15
}

$selectedDevice = Select-EmulatorDevice
if (-not $selectedDevice) {
    Write-Host "No emulator online - starting $AvdName..."
    if (Test-Path $emu) {
        Start-Process -FilePath $emu -ArgumentList @("-avd", $AvdName, "-no-snapshot-load", "-no-boot-anim") | Out-Null
    } else {
        flutter emulators --launch $AvdName
    }
    Start-Sleep -Seconds 20
    $deadline = (Get-Date).AddMinutes(5)
    do {
        $selectedDevice = Select-EmulatorDevice
        if ($selectedDevice) { break }
        Start-Sleep -Seconds 5
    } while ((Get-Date) -lt $deadline)
    if (-not $selectedDevice) {
        Write-Error "Emulator failed to start. Open Android Studio > Device Manager > Cold Boot for $AvdName."
    }
    Wait-ForEmulator -Serial $selectedDevice
} else {
    Write-Host "Using emulator: $selectedDevice"
}

$apk = Join-Path $Root "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apk)) {
    Write-Host "Building release APK (needed for emulator; first run can take several minutes)..."
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "Using existing release APK."
}

New-Item -ItemType Directory -Force -Path $screenshotsDir | Out-Null
Get-ChildItem $screenshotsDir -Filter "*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

if (-not (Test-Path $apk)) {
    Write-Host "Building release APK..."
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Start-AppFresh {
    & $adb -s $selectedDevice shell am force-stop $Package | Out-Null
    & $adb -s $selectedDevice shell pm clear $Package | Out-Null
    & $adb -s $selectedDevice shell am start -n $Activity | Out-Null
    Start-Sleep -Seconds 28
    # Dismiss Android notification permission dialog.
    Invoke-TapPercent $selectedDevice 0.50 0.59
    Start-Sleep -Seconds 6
}

function Capture-LoggedInTabs {
    Save-AdbScreenshot $selectedDevice "04-home-dashboard"
    Invoke-TapPercent $selectedDevice 0.37 0.96
    Start-Sleep -Seconds 4
    Save-AdbScreenshot $selectedDevice "05-my-orders"
    Invoke-TapPercent $selectedDevice 0.62 0.96
    Start-Sleep -Seconds 4
    Save-AdbScreenshot $selectedDevice "06-my-history"
    Invoke-TapPercent $selectedDevice 0.87 0.96
    Start-Sleep -Seconds 4
    Save-AdbScreenshot $selectedDevice "07-profile"
}

if ($env:SCREENSHOT_EMAIL -and $env:SCREENSHOT_PASSWORD) {
    Write-Host "Fresh install, then sign-in for logged-in screenshots..."
    Start-AppFresh
    Save-AdbScreenshot $selectedDevice "01-onboarding-welcome"
    Invoke-TapPercent $selectedDevice 0.50 0.93
    Start-Sleep -Seconds 2
    Save-AdbScreenshot $selectedDevice "02-onboarding-errands"
    Invoke-TapPercent $selectedDevice 0.90 0.05
    Start-Sleep -Seconds 5
    Save-AdbScreenshot $selectedDevice "03-sign-in"
    Sign-InViaAdb $selectedDevice $env:SCREENSHOT_EMAIL $env:SCREENSHOT_PASSWORD
    Write-Host "Capturing logged-in tab screens..."
    Capture-LoggedInTabs
} else {
    Write-Host "Capturing logged-in screens from existing emulator session (before wipe)..."
    & $adb -s $selectedDevice shell am force-stop $Package | Out-Null
    & $adb -s $selectedDevice shell am start -n $Activity | Out-Null
    Start-Sleep -Seconds 18
    $dashProbe = Join-Path $screenshotsDir "_probe.png"
    & $adb -s $selectedDevice shell screencap /sdcard/_probe.png | Out-Null
    & $adb -s $selectedDevice pull /sdcard/_probe.png $dashProbe | Out-Null
    $loggedIn = (Get-Item $dashProbe -ErrorAction SilentlyContinue).Length -gt 200000
    Remove-Item $dashProbe -Force -ErrorAction SilentlyContinue
    if ($loggedIn) {
        Capture-LoggedInTabs
    } else {
        Write-Host "No logged-in session on emulator; skipping dashboard/orders/profile."
    }

    Write-Host "Installing release build and capturing onboarding + sign-in..."
    flutter install -d $selectedDevice --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Start-AppFresh
    Save-AdbScreenshot $selectedDevice "01-onboarding-welcome"
    Invoke-TapPercent $selectedDevice 0.50 0.93
    Start-Sleep -Seconds 2
    Save-AdbScreenshot $selectedDevice "02-onboarding-errands"
    Invoke-TapPercent $selectedDevice 0.90 0.05
    Start-Sleep -Seconds 5
    Save-AdbScreenshot $selectedDevice "03-sign-in"
}

python tools/process_play_screenshots.py

Write-Host ""
Write-Host "Done. Upload files from store/google-play/screenshots/phone/ to Play Console."
if (-not $env:SCREENSHOT_EMAIL) {
    Write-Host 'Tip: Set SCREENSHOT_EMAIL and SCREENSHOT_PASSWORD for 4-8 logged-in screens.'
}
