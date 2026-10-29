@echo off
setlocal
REM Launch the real, hosted iOS Simulator testing workflow.
REM It does NOT install on iPhone and uses no paid macOS runner.
start "" "https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/simulator-lab.yml"
echo Bloub Native iOS Simulator Lab opened in the browser.
echo Click "Run workflow" to build and test.
echo The completed run provides native Simulator video, screenshots, XCTest logs and an Appetize-ready .app ZIP.
endlocal
