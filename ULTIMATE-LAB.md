# Bloub Ultimate Animation Lab — native iOS experimental suite

Status: **implementation in progress; do not claim a specific build passes until its GitHub Actions run is successful**.

## Open it

Open Bloub Avatar Lab → tap **OPEN BLOUB ULTIMATE ANIMATION LAB**. This opens a separate fullscreen native SwiftUI test UI; the original v4 controls remain available beneath it. From the lab you can pick four modes:

- **Showcase**: choose any of **38 independently selectable effects**, with intensity, particle count and trigger controls.
- **Stress**: combine multiple CPU/GPU effects at up to 60 Hz (simulator frame pacing varies); 20–600 particles; **Pause** is always available.
- **Compare**: original 24-frame Bloub morph against a selected live animated effect.
- **System**: Live Activity Dynamic Island state transitions, progress, pose parade and the 24-frame best-effort morph; expanded custom notification FX.

## 38 selectable effects

| Category | Experiments | Actual technology |
| --- | --- | --- |
| Avatar (12) | Original 24-frame morph, squash/stretch, bounce, blink, breathing, float, spin, gooey, split/merge, elastic, shake, explosion | SwiftUI TimelineView, CG transforms, original Bloub images, Canvas |
| Visual (10) | Particles, glow, neon pulse, ripple, shockwave, motion trail, animated blur, distortion, glitch, shader waves | SwiftUI Canvas, blend/blur, **stitchable Metal shaders** in `BloubShaders.metal` |
| 3D/physics (8) | Rotation3D, parallax drag, gyro tilt, gravity, collision, spring, depth layers, RealityKit sphere | 3D transforms, **CoreMotion**, **SpriteKit** dynamics, **RealityKit ARView(nonAR)** |
| Interactions (8) | Touch reaction, drag/throw, tap burst, hold, microphone reactive, sound sync, haptic patterns, gesture morph | SwiftUI Gesture, **AVAudioRecorder metering** (permission required), generated **original 660 Hz WAV**, **Core Haptics**, image/sprite scrub |

Not every experiment is a separate rendering engine. Several intentionally use different parameters/interaction modes of the same SwiftUI foreground renderer; the point is to test visible effects and supported APIs, not claim 38 distinct frameworks.

### Other iOS surfaces

- Six discrete **Island transition styles** triggered by `cycleIslandStyle`, stored as `BloubAttributes.ContentState.animationStyle`. The WidgetKit UI uses text/pose/progress/content transitions. The system has final control of timing and individual frame rendering.
- Expanded notification `bloubFX`: `glow`, `spin`, `shake`, `pulse`, `ripple`, `glitch`, and `morph`; implemented with UIKit `CAAnimation` and/or original 24-frame images. The collapsed banner is **not** custom-animated.
- Existing Home Screen / Lock Screen widgets and StandBy Live Activity view remain system-scheduled. They do **not** support continuous arbitrary animations. Controls may open Bloub on iOS 18+, but cannot show arbitrary custom animation on the system control itself. No actual agents are connected.
- **Interactive Home Widget**: NEXT POSE calls `CycleBloubPoseIntent` (App Intents / iOS 17+) and triggers a WidgetKit snapshot refresh. This stores state in the widget extension's local defaults; no external service.
- **Control Center / Lock Screen Control / Action Button** (iOS 18+): `BloubLaunchControlWidget` with `OpenBloubUltimateIntent` opens Bloub using a standard system symbol, not a freely animated control.
- In the performance overlay, **CADisplayLink FPS** is the app's main-loop sampling, not a hardware GPU profiler. "Long gaps" counts frame intervals over 37ms. Appetize stream lag can differ from the FPS on its simulator.

## Source files

- `BloubIsland/UltimateAnimationLab.swift`: catalogue, four modes, controls, performance/motion/audio probes
- `BloubIsland/BloubMotionStage.swift`: foreground 2D effects/Canvas, SpriteKit and RealityKit previews
- `BloubIsland/BloubShaders.metal`: two stitchable Metal shader functions
- `BloubIsland/ControlView.swift`: modal entry point, Live Activity style + notification FX
- `BloubNotificationContent/BloubNotificationViewController.swift`: expanded-notification custom effects
- `Shared/BloubAttributes.swift`, `BloubIslandWidget/BloubIslandWidget.swift`: per-state Island transition selection
- `BloubUITests/BloubSimulatorUITests.swift`: native screenshot + launch smoke test
- `project.yml`: microphone permission explanation

## Building and testing

Once source is committed and pushed to `main`, the configured [Auto-Deploy](https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/deploy-appetize.yml) compiles an ARM64 iPhone Simulator app on GitHub standard macOS runner and uploads it via secured Appetize API. Only claim success after both **Build** and **Upload** steps succeed.

Interactively open [Bloub Appetize](https://appetize.io/apps/ios/com.bloub.island.poc) and start a **new** session; previous sessions do not hot reload. [Simulator Lab](https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/simulator-lab.yml) runs automated XCUITest and records native video.

Do not install the experimental build on the physical iPhone 16 Pro until tested. Sensor, microphone and Core Haptics behavior may be absent on Appetize; verify on hardware later. Keep v4 IPA intact.

## Future work / known limitations

- iPhone 16 Pro preferred for the headless simulator, with fallbacks if not installed on GitHub macOS image.
- Validate iOS 18 Control Center / Action Button open intent and interactive Home Widget on the physical iPhone 16 Pro; simulator support is limited.
- Broaden native UI tests, inspect the actual Dynamic Island UI, and measure hardware thermal and animation throttling.
- No API keys in source; Appetize secret stays in GitHub Actions. No agent backend, push notifications or external soundtracks are connected.

Reference: [SESSION-HANDOFF.md](SESSION-HANDOFF.md).
