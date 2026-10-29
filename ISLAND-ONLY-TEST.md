# Bloub: OUTSIDE-APP Dynamic Island Alert Test

**Main target:** iPhone 16 Pro. **No banner notification** is created by the new Island-only workflow. It uses **ActivityKit's `Activity.update(_:alertConfiguration:)`**, documented by Apple to request an expanded Live Activity presentation in Dynamic Island on supported iPhones. The iOS system decides whether and when it expands; the app cannot force it to appear for every event.

**Build verification — 29 Oct 2026:** iPhone device IPA successfully compiled, packaged and checked in [GitHub run 40883729822](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40883729822). Windows file: `artifacts/BloubIslandOnly-iPhone16Pro-unsigned.ipa`, **1,849,637 bytes**, SHA-256 `55cdf489fa0786eab6d764120967a85fd78fcf85e5b8fc307dfb919af2b38833`. Both WidgetKit and Notification Content extensions plus NSSupportsLiveActivities are present. Appetize Auto-Deploy [run 40883729595](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40883729595) succeeded. This does **not** verify real hardware Island appearance yet.

## How to test on physical iPhone (most important)

1. Install the **newly rebuilt** `artifacts/BloubIslandOnly-iPhone16Pro-unsigned.ipa` through Sideloadly with your Apple Account; keep `artifacts/BloubAvatarLab-v4-original-morph-verified.ipa` as a backup. Do not use the older IPA built before this Island-only change.
2. Open `Bloub Avatar Lab` → **START ISLAND** if it is not already active. Confirm Live Activities are enabled in iPhone Settings for Bloub.
3. Tap **⚠️ APPROVAL POPUP · 8s** then **swipe Home immediately**. Keep iPhone unlocked and on Home Screen until the 8-second mark.
4. Look for an **Expanded Dynamic Island Live Activity** (orange alert text/avatar). This is requested through `AlertConfiguration`, **not** a `UNNotificationRequest` and **not** a standard incoming-notification banner.
5. Repeat separately with **ERROR POPUP** and **COMPLETED POPUP**. Use **SILENT ISLAND UPDATE** as a control: it updates the pose/progress without requesting expanded presentation.
6. To compare shape rendering, tap **MORPH FRAMES · 10s** then swipe Home. The 24 frames are best-effort state updates and iOS may show only a subset.
7. Record iPhone's screen during the test. Capture Home Screen and Dynamic Island at the moment of update. For best comparison, try the device unlocked, without Focus / Do Not Disturb, without another high-priority Live Activity, and with volume up.

## Supported vs unsupported

- **Supported request:** `Activity.update(ActivityContent, alertConfiguration: AlertConfiguration(...))`. Apple documentation: https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities and https://developer.apple.com/documentation/activitykit/activity/update(_:alertconfiguration:).
- **Supported design:** WidgetKit Expanded / Compact / Minimal regions, changing Bloub pose, size, color, progress and short SwiftUI state transitions. **These transitions are system-managed**; not a video loop.
- **Not supported by public APIs:** forcing Dynamic Island to expand for every local event, overriding third-party/system notifications, or playing arbitrary 12/60fps sprite/video loops from a widget. No honest build can promise that.
- **Execution caveat:** The 8s delayed demo uses `UIApplication.beginBackgroundTask`, which iOS can expire. It is suitable for a short local experiment, not a dependable production background alert dispatcher. Real agent-originated alerts when the app is suspended require an allowed **Live Activity push-update** architecture/APNs or other permitted background execution; none is configured in this offline test.
- The previous `UNNotificationContentExtension` and in-app animation playground source remain in the repo for rollback/comparison, but they are **not part of the new primary test flow**.

## Technical notes

- `BloubLab.islandPopupAfterEightSeconds(_:)`: one local Live Activity initial state update, an 8-second background task, then `Activity.update(..., alertConfiguration: .default sound)`.
- `BloubLab.islandSilentAfterEightSeconds()`: same delayed state update but **no AlertConfiguration** for comparison.
- `BloubAttributes.ContentState.islandAlertStage` / `islandAlertTick`: discrete alert state and transition trigger (optional to tolerate old Live Activities).
- `BloubLiveActivityWidget`: larger alert avatar, warning label, short SwiftUI scale/opacity/spring changes in the system-managed Dynamic Island regions.
- `ControlView`: replaced foreground showcase with outside-app-only controls, and removed normal notification banner buttons from the UI.
- `BloubUITests`: automated launch/arm/background smoke tests. They cannot assert that iOS rendered an expanded Island without visual hardware validation.
- CI: [Device IPA build](https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/build-ios.yml), [Appetize auto deploy](https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/deploy-appetize.yml), [Native Simulator XCTest](https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/simulator-lab.yml).

**Not finished until** a new device IPA Build and Appetize Simulator build pass, and the user verifies popup/animation behavior on the physical iPhone.
