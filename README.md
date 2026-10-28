# Bloub Avatar Lab — Offline iPhone Experiment (v2)

**No OpenClaw, Craft, Pilot, servers, remote agent tools, APNs, or production credentials.**
This is an on-device UI experiment using the same Native SwiftUI / ActivityKit / WidgetKit implementation that passed the first iPhone test.

## What this build tests

- **In-app Bloub avatar:** six real Bloub-04 sprite sheets, 144 original frames per state, playing at ~12 fps while the app is open; subtle SwiftUI 3D tilt and floating motion (not a 3D mesh).
- **Dynamic Island:** compact, minimal, expanded (long-press), status changes, different original Bloub avatar artwork, progress, an Attention alert using ActivityKit.
- **Lock Screen:** Live Activity layout and static Bloub Lock Screen widgets (circular, rectangular, inline).
- **Home Screen:** small and medium Bloub widgets — **static snapshots** by iOS design, not continuously animated widgets.
- **Local Notifications:** request permission, send a simulated banner after two seconds, two notification actions, and original Bloub avatar attachment for notification expansion.

## Test on a real iPhone

1. Upgrade by installing the new IPA with Sideloadly using the **same** Apple account and bundle ID as v1. If the first version has a running Live Activity, tap End in the old app first.
2. Open **Bloub Avatar Lab**. Select Working, Approval, Completed, Sleeping, Error, Idle. Verify the character animates inside the app.
3. Under **Dynamic Island**, tap **Start** then tap **Island alert in 10s · Go Home**. Immediately swipe Home (without force-quitting Bloub) and observe the Island around the 10-second mark. A short `UIApplication.beginBackgroundTask` keeps the test active briefly but **iOS may suspend/expire it** and **iOS controls whether an expanded Island appears**. Use **Instant alert (comparison)** while in-app only as a control; the system may hide its Island presentation behind the foreground app.
4. Tap Enable Notifications, then **Banner in 10s · Go Home**, and immediately swipe Home. This schedules a separate **local notification** that does not depend on the app remaining active. Long-press the banner to inspect Bloub artwork. Focus/notification settings can suppress banners. You may use the 2-second immediate banner for comparison.
5. Start Live Activity, lock the iPhone. Check the Lock Screen. On Home Screen, long-press a blank area → Edit → Add Widget → search for Bloub. Add small/medium widget. For Lock Screen, customize Lock Screen → Add Widgets → Bloub.
6. Tap Stop Live Activity to finish the experiment.

## iOS limits

- Dynamic Island and Live Activity animations are system-managed and short, **not** continuous 3D or sprite loops.
- Actual animation loops only run inside the app. WidgetKit snapshots are not continuous video.
- Local notifications need permission; presentation, size and timing are controlled by iOS and Focus settings. The 10-second local notification is system scheduled; the 10-second Island update is a **best-effort short background task**, not a guaranteed scheduler or APNs update.
- Dynamic Island does not appear in the normal way above its own foreground app. To test transient expansion, send the delayed alert and leave Bloub for Home immediately.
- Free Apple Account sideload installs need refreshing (typically within 7 days) and may impose extension/signing limitations.
- 3D tilt is a SwiftUI visual effect, **not** a RealityKit 3D character.
- The first step proves app behavior only. There is no real connection to agent processes.

## Build

GitHub Actions workflow **Build Bloub Island POC** builds on the hosted macOS runner, verifies both app and widget extension metadata, then packages a **new unsigned IPA**. Install on Windows using Sideloadly.

## Original art

Uses original Bloub-04 sprite sheets in the local `sileo-standalone-demo/public/bloub` folder. The files were copied into this experimental iOS project; the source demo was not modified.
