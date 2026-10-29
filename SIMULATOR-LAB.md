# Bloub Native iOS Simulator Lab

This is the **real Native SwiftUI/ActivityKit/WidgetKit app**, built and tested on an Apple iPhone Simulator hosted by GitHub Actions. It is **not** an HTML/Windows mock-up.

## Start a test from Windows

1. Open https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/simulator-lab.yml
2. Select **Run workflow** → **main**.
3. In the completed run, download:
   - **Bloub-Native-Simulator-Evidence**: `Bloub-native-simulator.mp4`, screenshots, `BloubUITests.xcresult` and Xcode logs.
   - **Bloub-Appetize-ARM64-Simulator-Build**: `Bloub-Appetize-ARM64-Simulator.zip`, a *real* ARM64 Simulator `.app` bundled for Appetize.io.
4. Inspect video and results on Windows. No physical iPhone installation is required to iterate here.

The XCUITest automation launches the actual Bloub app and runs a second scenario that triggers the **original 24-frame circle-to-triangle** ActivityKit update after ten seconds, while the app is on SpringBoard. iOS may collapse its updates, so the test is an integration smoke check **not proof of 12 FPS rendering**.

## Appetize interactive use (optional)

Apple Simulator builds are not device IPAs. `Bloub-Appetize-ARM64-Simulator.zip` is the correct artifact to upload to https://appetize.io/; the existing `BloubAvatarLab-v4-original-morph-verified.ipa` is only for Sideloadly / real iPhone.

**Appetize is connected as of 2026-10-29:** the user confirmed the app runs in Appetize, and GitHub Actions auto-deploy succeeded (run [40847983431](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40847983431)). The API token is stored only as the GitHub Actions repository secret `APPETIZE_API_TOKEN`. No manual ZIP upload is required for subsequent source changes pushed to `main`. See [AUTO-DEPLOY.md](AUTO-DEPLOY.md) and [SESSION-HANDOFF.md](SESSION-HANDOFF.md). Live Activity frame pacing still requires testing on real hardware.

## Cost and limitations

Public GitHub repositories using **standard** macOS runners are not billed for GitHub Actions minutes under current GitHub policy. The Simulator-only workflow uses `macos-15-intel` and selects Xcode 16.4 where available (iPhone 16 Pro on iOS 18.5). Device IPA and Appetize Auto-Deploy remain on their previously verified macOS runner; it does not use paid large runners. Public repository source and build artifacts are visible to others: **do not commit secrets or private data**.

GitHub Actions is headless automation, not a live Mac desktop. Simulator results can differ from real iPhone behavior, and user interaction is more convenient using Appetize (subject to its own free-plan limits). The source app's regular behavior and the working v4 IPA are unchanged; the only new app activation is a simulator-only `--bloub-sim-morph` test argument.

## Infrastructure reliability / current UI test status

- [Run 40863013746](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40863013746) **did not reach UI assertions** because the iPhone 17 Pro iOS 26.4 simulator boot exceeded 180s, and Xcode then reported no available test destination (exit 70). The Simulator app still compiled; the 38-effect Appetize Auto-Deploy and device IPA build passed separately.
- Updated workflow runs on `macos-15-intel` + Xcode 16.4 (target iPhone 16 Pro / iOS 18.5), falling back when unavailable. It waits for boot with a clear failure if still unavailable, checks Xcode destinations and prints retained native test logs. Previous `macos-26-intel` / Xcode 26.6 runner repeatedly stalled during simulator boot. Do not mistake a CI infrastructure failure for app behavior validation.

## Maintenance

- Code edits on Windows → Git push.
- Trigger `Bloub Native iOS Simulator Lab` only when you want simulator evidence; the workflow is intentionally not triggered by every source edit.
- The existing `Build Bloub Island POC` workflow still creates a real-device unsigned IPA separately.
- Install to the user's iPhone only after a milestone is accepted, for final hardware behavior validation.
