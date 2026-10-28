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
3. Under **Dynamic Island**, tap Start, return to Home Screen, long-press Island, tap +20%, try Attention / big alert. iOS chooses whether/when to transiently expand the island. You **cannot** force a permanent large Island.
4. Tap Enable Notifications and Send test banner. When presented, long-press the banner for the Bloub image. Allow notifications in Settings if prompted. You may also test from Home Screen.
5. Start Live Activity, lock the iPhone. Check the Lock Screen. On Home Screen, long-press a blank area → Edit → Add Widget → search for Bloub. Add small/medium widget. For Lock Screen, customize Lock Screen → Add Widgets → Bloub.
6. Tap Stop Live Activity to finish the experiment.

## iOS limits

- Dynamic Island and Live Activity animations are system-managed and short, **not** continuous 3D or sprite loops.
- Actual animation loops only run inside the app. WidgetKit snapshots are not continuous video.
- Local notifications need permission; presentation, size and timing are controlled by iOS and Focus settings.
- Free Apple Account sideload installs need refreshing (typically within 7 days) and may impose extension/signing limitations.
- 3D tilt is a SwiftUI visual effect, **not** a RealityKit 3D character.
- The first step proves app behavior only. There is no real connection to agent processes.

## Build

GitHub Actions workflow **Build Bloub Island POC** builds on the hosted macOS runner, verifies both app and widget extension metadata, then packages a **new unsigned IPA**. Install on Windows using Sideloadly.

## Original art

Uses original Bloub-04 sprite sheets in the local `sileo-standalone-demo/public/bloub` folder. The files were copied into this experimental iOS project; the source demo was not modified.
