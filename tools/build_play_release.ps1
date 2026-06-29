# Builds the Google Play upload bundle with Mapbox dependencies prefetched first.
# Run from project root:  .\tools\build_play_release.ps1

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Building Play Store app bundle..."
# Mapbox artifacts are prefetched automatically before assembleRelease/bundleRelease.
flutter build appbundle --release
exit $LASTEXITCODE
