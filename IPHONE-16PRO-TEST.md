# Bloub Dynamic Island Alert Lab — iPhone 16 Pro hardware test

> **CURRENT PROCEDURE (verified device IPA):** [ISLAND-ONLY-TEST.md](ISLAND-ONLY-TEST.md). Use `artifacts/BloubIslandOnly-iPhone16Pro-unsigned.ipa` (SHA-256 `55cdf489fa0786eab6d764120967a85fd78fcf85e5b8fc307dfb919af2b38833`) via `START-IPHONE16PRO-TEST.cmd`. Device CI [40883729822](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40883729822) passed. All old Ultimate Lab IPA/38-effect instructions below are **historical** and are not the test to follow.

> **Native build readiness (29 Oct 2026).** The latest implemented Bloub app (38 selectable effects + system surface tests) compiled successfully for **iPhone device** and uploaded to Appetize. Native iOS Simulator UI tests passed **3/3** on Xcode 26 in [run 40866761278](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40866761278). This is **NOT yet a claim of physical iPhone installation or verification**. The actual iPhone 16 Pro test must be performed by the user.

## Ready-to-install files on Windows

Repository root:
```text
D:\Projects\Pilot-Planning\Pilot-Code\workspaces\bloub-island-poc-20261028
```

| File | Purpose |
| --- | --- |
| `artifacts/BloubUltimateLab-iPhone16Pro-unsigned.ipa` | **Use this FINAL** 2,016,974-byte native iPhone build. SHA-256 `f7d8fd1f4043f4d66d4b382142262448100a0c277e2a820c032755ce3fc70848` verified against the **latest successfully built GitHub device artifact** [run 40876807338](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40876807338), artifact `BloubUltimateLab-iPhone-IPA`. The verified IPA was copied back to this Windows path. |
| `artifacts/BloubAvatarLab-v4-original-morph-verified.ipa` | **Keep** known-working v4 IPA for recovery. Never overwrite or delete as part of this test. |

Sideloadly is already installed locally at `C:\Users\theej\AppData\Local\Sideloadly\Sideloadly.exe` (checked on Windows).

**NOTE:** The IPA is **unsigned**, intentionally. GitHub cannot sign it with the user's free Apple ID; Sideloadly does signing locally. Do **not** attempt to upload this iPhone IPA to Appetize, which uses a different Simulator ZIP. The iPhone app's Bundle ID is `com.bloub.island.poc` and iOS deployment target is 17.0.

**Windows shortcut:** double-click `START-IPHONE16PRO-TEST.cmd` in the project root to launch the existing Sideloadly and select the verified IPA in Explorer. It never signs or installs automatically; you remain in control.

## Install once on iPhone 16 Pro (Windows, no Mac, free Apple ID)

1. Connect the unlocked iPhone 16 Pro to the Windows laptop over USB, accept **Trust This Computer** on the phone. Launch the installed **Sideloadly** (not the web simulator).
2. Drag `artifacts/BloubUltimateLab-iPhone16Pro-unsigned.ipa` into Sideloadly. Select **your iPhone 16 Pro** and enter **your own Apple ID** if prompted. Keep the existing Apple ID and bundle ID settings used for v4 wherever possible.
3. Click **Start** in Sideloadly and follow its prompts. This signs the unsigned IPA with the user's own Apple credentials and installs it.
4. On the phone, if requested: **Settings → General → VPN & Device Management → trust the Developer App** corresponding to the Apple ID. For developer-mode prompts, **Settings → Privacy & Security → Developer Mode**, enable and restart as instructed.
5. Open **Bloub Avatar Lab** → select **OPEN BLOUB ULTIMATE ANIMATION LAB**.

The same signing identity and bundle ID will typically update the old sideloaded copy. If the sideload install reports an App ID / extension profile limit or signature mismatch, record the **exact Sideloadly error** and do not delete the working v4 until a replacement is confirmed. A free Apple ID generally has seven-day sideload signing validity and limited active App IDs.

## Suggested hands-on test sequence

- **Foreground animation**: Ultimate Lab → Showcase → cycle through 38 experiments (Avatar 12, Visual 10, 3D/Physics 8, Interaction 8); use Intensity slider, particle slider, Trigger and Pause. Watch for freeze, blank stage, rendering error or crash.
- **Stress mode**: try default first, then gradually increase particles towards 600; read the on-screen CADisplayLink FPS / frame gap and thermal status. **Stop/Pause if the phone gets hot**. Do not confuse Appetize stream lag with native device FPS.
- **3D and hardware**: RealityKit sphere, SpriteKit gravity/collision; tilt the phone for Gyroscope mode; enable microphone only on user request and observe levels; tap Sound / Haptics on real phone.
- **Dynamic Island**: System → Start Island → press Home → long-press Island to expand; try Next pose / Next style / +20% / Alert and delayed 24-frame morph. The 24 original frames are **ActivityKit updates, not guaranteed 12fps** on the real Island.
- **Expanded notification**: System → choose FX `glow/spin/shake/pulse/ripple/glitch/morph`, schedule delayed notification → lock/leave app → long-press notification to expand. Collapsed banner is Apple-controlled.
- **Widgets / Controls**: add Bloub Home widget and try **NEXT POSE**. On iOS 18+, add Bloub Lab Control in Control Center; configure Action Button to use it if available. These are system-managed controls, not full-time sprite animations.
- **Lock Screen / StandBy**: test the existing Live Activity and Lock Screen widget while the phone is locked, then optional StandBy during charging. Confirm which surfaces show static vs updated states.

**Capture a screenshot or short video of the real phone for any missing effect**. List the experiment name and behavior. A screenshot/video is especially useful for Island rendering and the Control Widget.

## What was verified vs what still requires hardware

| Test | Status |
| --- | --- |
| Device IPA produced by Xcode 26.6, bundled extensions, source assets | PASS (latest CI run 40876807338; IPA extracted, rechecked and copied to Windows) |
| Appetize Auto-Deploy (Simulator app build) | PASS (run 40863013737) |
| Native Simulator XCUITest — app launch, background morph, Ultimate Lab screen | PASS 3/3 (run 40866761278) |
| Real iPhone 16 Pro: successful Sideloadly signing/installation | **NOT YET TESTED** |
| Real iPhone 16 Pro: native GPU/physics effects, Live Activity frames, Haptics, microphone, gyro, Control Center | **NOT YET TESTED** |

Official install references: https://sideloadly.io/faq and https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device.

Use [SESSION-HANDOFF.md](SESSION-HANDOFF.md), [ULTIMATE-LAB.md](ULTIMATE-LAB.md) and [SIMULATOR-LAB.md](SIMULATOR-LAB.md) to resume.
