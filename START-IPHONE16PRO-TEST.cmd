@echo off
setlocal
set "APP_ROOT=%~dp0"
set "IPA=%APP_ROOT%artifacts\BloubIslandOnly-iPhone16Pro-unsigned.ipa"
set "SIDELOADLY=%LOCALAPPDATA%\Sideloadly\Sideloadly.exe"

if not exist "%IPA%" (
  echo [ERROR] Missing verified device IPA:
  echo %IPA%
  echo See IPHONE-16PRO-TEST.md in this project.
  pause
  exit /b 1
)

if exist "%SIDELOADLY%" (
  start "" "%SIDELOADLY%"
) else (
  echo Sideloadly not found at the previously confirmed installation path.
  echo Open Sideloadly manually: https://sideloadly.io/
)

explorer.exe /select,"%IPA%"
echo.
echo BLOUB DYNAMIC ISLAND-ONLY ALERT TEST - iPhone 16 Pro
echo 1. Connect and unlock iPhone 16 Pro via USB.
echo 2. In Sideloadly, select that iPhone and your Apple ID.
echo 3. Drag highlighted IPA into Sideloadly and press Start.
echo 4. Trust developer / enable Developer Mode if prompted.
echo    Live Activities must be enabled for Bloub in iPhone Settings.
echo 5. Open Bloub Avatar Lab, press START ISLAND and then APPROVAL POPUP 8s.
echo 6. Swipe Home immediately and watch the Dynamic Island expansion.
echo.
echo IMPORTANT: This script DOES NOT sign/install automatically.
echo The original known-good v4 IPA is kept unchanged.
echo Full instructions: ISLAND-ONLY-TEST.md
pause
