# Bloub Outside-App Animation Lab v3

**Purpose:** discover the practical maximum of Bloub avatar movement on iOS surfaces outside the foreground app. This remains a 100% local, offline UI experiment. No OpenClaw, Craft, Pilot, remote agents, APNs, background server or Apple paid account.

## What is new in v3

- **Dynamic Island + Lock Screen Live Activity:** five real sprite poses per mood (source frames 0, 3, 48, 72, 120), rendered using original Bloub 04 art. Press **NEXT Bloub pose on Island** to issue a discrete update; system-managed image transitions may animate.
- **5-pose Island parade in 10s:** start Live Activity, trigger delayed parade, immediately swipe to the Home Screen. The app uses a short background execution request and submits five successive poses at ~0.9s intervals. **This may be throttled or coalesced by iOS**; the experiment measures that limitation and is not a guaranteed animation loop.
- **Island alert in 10s:** send a single, high-relevance attention update after exiting the app. iOS decides if the expanded Island is displayed.
- **Rich expanded notification:** includes a dedicated Notification Content Extension using UIKit and original 144-frame Bloub 04 sprite sheets for six emotions. Press **Banner in 10s · Go Home**, leave the app, and **long-press the delivered banner**: the expanded notification attempts to play a 12 FPS animated Bloub. The *collapsed* banner remains system-drawn and is not freely animated.
- **Home / Lock Screen Widgets:** iOS WidgetKit timeline with four mood/pose snapshots spaced 20 minutes apart. iOS owns update timing and may defer/coalesce snapshots; no continuous loop. Lock Screen **Live Activity** changes with the real ActivityKit pose separately.
- **In-app frame counter:** retained only as a technical diagnostic, not as the primary feature.

## On-device test sequence

1. Stop any active Live Activity in the previous version. Install this v3 IPA via Sideloadly using the **same Apple Account and app ID**.
2. Open Bloub Avatar Lab → **Start** → swipe Home → verify compact Island. Return to app, tap **NEXT Bloub pose on Island**, and return Home. Repeat to see new poses.
3. Tap **5-pose Island parade in 10s**, then immediately swipe Home. Watch Island. Possible outcomes: several frame changes, only the last, or none (iOS controls local update delivery). Do not force-quit the app.
4. Tap **Island alert in 10s**, swipe Home. Watch for temporary expanded Island + sound/haptic. This is still system controlled.
5. Allow Notifications. Tap **Banner in 10s · Go Home**, then swipe Home. When the banner appears, **long-press it** to reveal the custom expanded notification and play Bloub animation. If it shows only the default expansion, the rich content extension may not have loaded or signed correctly; capture screenshot.
6. Lock iPhone while a Live Activity is active to check changing Bloub pose. Add small/medium Bloub Home Widget and circular/rectangular Lock Widget to test slowly scheduled pose updates.

## Important platform limits

- Apple documents **max 2 seconds** for a single Live Activity/Widget transition. These are state-change animations, not an arbitrary timer-driven Sprite loop. The system ignores `.animation(...)` in Live Activity View builders and owns the timing.
- Collapsed Notification Banners cannot use custom continuously animated UIViewControllers. Apple's Notification Content Extension becomes visible on **expanded** notification only.
- Home/Lock widgets have timelines with system-controlled refresh and are not continuous sprite video.
- Background execution requested for a local 10s burst is **best-effort**. Real unattended background delivery normally needs platform-approved update paths; this offline POC intentionally has no APNs/backend.
- A free Apple Account may refuse to sign an additional notification extension even when the previous WidgetKit extension worked. If Sideloadly errors, record the exact error; revert to the last working IPA rather than weakening security.
- Real iPhone tests are the source of truth for every rendering claim.

## Source and build

Source sprites copied (not modified) from `sileo-standalone-demo/public/bloub`. iOS uses SwiftUI, ActivityKit, WidgetKit, UIKit, UserNotificationsUI. GitHub Actions builds and verifies the app plus **two embedded extensions**, and packages an unsigned IPA to be signed and installed with Sideloadly.
