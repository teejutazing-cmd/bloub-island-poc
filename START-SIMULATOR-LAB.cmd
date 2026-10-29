@echo off
setlocal
set "HERE=%~dp0"
set "RESULTS=%HERE%artifacts\simulator-lab"

REM Opens the real SwiftUI/ActivityKit iOS Simulator CI workflow in a browser.
REM Does not run or install any app on the user's physical iPhone.
start "" "https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/simulator-lab.yml"
echo Opened Bloub native iOS Simulator CI. Click Run workflow when needed.

if exist "%RESULTS%\Bloub-Simulator-Test.mp4" (
  echo Opening the latest downloaded native Simulator recording.
  start "" "%RESULTS%\Bloub-Simulator-Test.mp4"
)
if exist "%RESULTS%\Bloub-Appetize-Ready.zip" (
  echo Appetize-ready ZIP and XCTest evidence are in:
  echo %RESULTS%
  start "" "%RESULTS%"
)
echo.
echo No Mac, iPhone USB, or physical-device installation is required.
endlocal
