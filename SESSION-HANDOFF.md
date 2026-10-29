# Bloub iOS Native — Session Handoff / คู่มือส่งต่องาน

> **สถานะยืนยัน ณ 29 ตุลาคม 2026** · อ่านหน้านี้ก่อนเริ่ม ChatGPT session ใหม่
>
> **Bloub เป็น iOS app จริง** (SwiftUI + ActivityKit + WidgetKit + Notification Content Extension) ไม่ใช่เว็บหรือรูป mockup. ระบบ **GitHub Actions → Appetize auto-deploy ใช้งานได้แล้ว**. ยังไม่มี AI agent/backend จริง

## อัปเดตล่าสุด — Ultimate Animation Lab (29 ต.ค. 2026)

- เพิ่ม **Bloub Ultimate Animation Lab** ที่เปิดจากปุ่มในแอปเดิม: 38 selectable effects / 4 modes (**Showcase, Stress, Compare, System**). รายละเอียดครบที่ [ULTIMATE-LAB.md](ULTIMATE-LAB.md)
- เพิ่ม **Metal shader (warp / color shift)**, **SpriteKit collisions/gravity**, **RealityKit non-AR sphere**, **CoreMotion gyro**, **Core Haptics**, **microphone audio meter**, สังเคราะห์เสียง WAV ภายในแอป, particles, gestures และ FPS monitor
- Dynamic Island: ทดลอง transition styles 6 แบบผ่าน ActivityKit state updates (ระบบ iOS ไม่รับประกันทุกเฟรม)
- Expanded Notification: glow/spin/shake/pulse/ripple/glitch/morph ด้วย Core Animation ภายใน Notification Content Extension
- Home Widget: ปุ่ม **NEXT POSE** ผ่าน App Intent; Control Center / Action Button บน iOS 18+ มี **Bloub Lab Control Widget** สำหรับเปิดแอป (ระบบควบคุมรูปแบบ Animation)
- ✅ Native iPhone unsigned IPA Build [40863013726](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40863013726) ผ่าน. ✅ Auto-Deploy Simulator ไป Appetize [40863013737](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40863013737) ผ่าน. ✅ Native XCTest **3/3 PASS** บน Xcode 26 [40866761278](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40866761278) โดยเลือก runtime ที่บูตได้, รอ boot และเช็ก `xcodebuild -showdestinations`. การลอง Xcode 16.4 [40868009706](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40868009706) ล้มเหลวจากข้อจำกัด Swift Compiler; จึงกลับไปใช้ Xcode 26 สำหรับ Simulator Lab
- Xcode 26 macOS runner ต้องติดตั้ง `metalToolchain` เพิ่มด้วย `xcodebuild -downloadComponent metalToolchain`; ยังคงใช้ใน IPA/Auto-Deploy ที่ผ่านแล้ว ส่วน Native Simulator XCTest ใช้ macOS 26 Intel / Xcode 26.6 ตามรอบที่ผ่าน 3/3 Tests; Runner อาจไม่มี iPhone 16 Pro จึง fallback เป็น iPhone 17 Pro และเลือก runtime ที่บูตได้
- **ยังไม่ได้ยืนยัน** Control Center/Action Button และ Haptics/Mic/Gyro บน iPhone จริง; ไม่ควรอ้างความลื่นของ Island 24fps/12fps
- **ยังไม่มี Agent backend จริง**, ยังไม่ใช้เซิร์ฟเวอร์หรือ APNs. รักษา IPA v4 ของเดิมไว้, ไม่ต้องตั้งค่า Appetize Secret ใหม่
- **Source truth:** GitHub `main`; เปิด [Bloub บน Appetize](https://appetize.io/apps/ios/com.bloub.island.poc) แล้ว Start **session ใหม่** หลัง CI Upload success

**เตรียมทดลองเครื่องจริง:** ไฟล์ `artifacts/BloubUltimateLab-iPhone16Pro-unsigned.ipa` (SHA-256: `f7d8fd1f4043f4d66d4b382142262448100a0c277e2a820c032755ce3fc70848`) ผ่านการตรวจ ZIP, Bundle ID และทั้งสอง Extensions บน Windows แล้ว; Sideloadly ติดตั้งแล้วที่ `C:\Users\theej\AppData\Local\Sideloadly\Sideloadly.exe`. ดับเบิลคลิก `START-IPHONE16PRO-TEST.cmd` เพื่อเปิด Sideloadly และเลือก IPA บน Windows (ยังไม่ติดตั้งอัตโนมัติ). คู่มือ: [IPHONE-16PRO-TEST.md](IPHONE-16PRO-TEST.md). **ยังไม่ติดตั้ง/ยืนยัน Animation บน iPhone 16 Pro จริง**

## 1) เป้าหมายและข้อกำหนดที่ตกลงกับผู้ใช้

- พัฒนา **Bloub avatar** ที่ใช้ภาพ/animation ต้นฉบับใน Dynamic Island, Lock Screen, Home/Lock widgets และการแจ้งเตือนบน iOS; ขณะนี้เป็น **offline prototype** และ bot จำลอง
- ผู้ใช้มี **iPhone 16 Pro** และพัฒนาโดยใช้ **Windows laptop ไม่มี Mac**; ต้องการใช้ของฟรีเป็นหลัก
- เน้น **native iOS** ไม่ใช้ HTML mockup มาทดแทน; ต้องการดู/ลองใน Appetize ก่อน และค่อยลง iPhone จริงเฉพาะเมื่อครบ milestone
- เมื่อเปลี่ยน source แล้วต้อง **Push ไป GitHub `main`** เพื่อให้ Appetize ได้ Build ใหม่อัตโนมัติ; **Session ที่เปิดอยู่จะไม่ hot-reload**
- อย่าเริ่มสร้างโปรเจกต์ใหม่/ตั้งค่า Appetize ซ้ำ หากไม่มีปัญหาจริง ใช้ repo นี้เป็น source of truth
- Sileo/Bloub สำหรับ Windows desktop เป็นอีกแนวทางหนึ่ง **ไม่ใช่ iOS native repo นี้**

## 2) ลิงก์หลัก (เปิดเพื่อทำงานต่อ)

| รายการ | URL |
| --- | --- |
| GitHub source | https://github.com/teejutazing-cmd/bloub-island-poc |
| Bloub Appetize (แอปเดิมและอัปเดตล่าสุด) | https://appetize.io/apps/ios/com.bloub.island.poc |
| **Auto-Deploy workflow** | https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/deploy-appetize.yml |
| **Auto-Deploy ครั้งแรกที่สำเร็จ (#2)** | https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40847983431 |
| Native iOS Simulator + XCTest + วิดีโอ | https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/simulator-lab.yml |
| Build unsigned device IPA | https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/build-ios.yml |
| GitHub Actions secrets | https://github.com/teejutazing-cmd/bloub-island-poc/settings/secrets/actions |

Windows repo folder (on user's laptop):
```text
D:\Projects\Pilot-Planning\Pilot-Code\workspaces\bloub-island-poc-20261028
```

Git branch: `main` · Remote: `origin` → repo above · Bundle ID: `com.bloub.island.poc`.

## 3) สิ่งที่สร้าง/ติดตั้งไว้แล้ว

### Native iOS app / original sprite

- `BloubIsland/` — SwiftUI app / `ControlView.swift` มีปุ่ม Start, ActivityKit experiments, notifications, in-app playground
- `BloubIslandWidget/` — Dynamic Island / Live Activity / Home และ Lock Screen widget views
- `BloubNotificationContent/` — Notification Content Extension สำหรับ animation เมื่อ **ขยาย notification**
- `Shared/` — model และภาพจาก original Bloub sprite, รวม `Shared/BloubAssets.xcassets/bloub-morph-00...23.imageset`
- `project.yml` — XcodeGen project definition, iOS deployment target **17.0**, schemes `BloubIsland` และ `BloubSimulatorLab`
- `BloubUITests/BloubSimulatorUITests.swift` — 2 native UI tests สำหรับ app launch และ morph scenario ขณะ app ไป Home Screen
- Original sprite `bloub-04-working.png` มี 144 frames (9216×64, ขนาดเฟรม 64×64); circle→triangle ใช้ 24 original frames (indices 0,3,...,69), ตั้งใจแสดง 2 วินาที (~12fps)

**ข้อจำกัด iOS:** ActivityKit เปลี่ยน 24 states ได้ แต่ **iOS อาจรวม/ทิ้งเฟรม**; ห้ามอ้างว่าดู Dynamic Island ได้ 12fps จริงโดยไม่มีภาพทดสอบ. Expanded Notification เล่น sprite ด้วย `UIImageView.animationImages` ได้หลังผู้ใช้ long-press เพื่อขยายเท่านั้น. Widgets ไม่สามารถเล่น animation ต่อเนื่องอิสระแบบ video ได้

### 3 GitHub Actions workflows

1. **`.github/workflows/deploy-appetize.yml`** — ระบบหลักสำหรับพัฒนาต่อ: ทุก Push เข้า `main` ที่แก้ source, assets, `project.yml` หรือ workflow นี้ จะ build **ARM64 Simulator `.app`** → ZIP → upload via `appetizeio/github-action-appetize@v1.1.0` โดยใช้ GitHub Actions Secret `APPETIZE_API_TOKEN`. สร้าง build ใหม่ภายใต้ **bundle ID เดิม**, ไม่ overwrite build history. มี `workflow_dispatch` เพื่อกดรันเองได้. รันพรีไฟลต์เท่านั้นหากไม่มี Secret. `permissions: contents: read`. การแก้ docs อย่างเดียว **ไม่กระตุ้น build**
2. **`.github/workflows/simulator-lab.yml`** — Manual/เมื่อแก้ workflow: build simulator native + XCTest + `simctl` screen recording, PNG, `.xcresult` และ logs เป็น artifacts; ไม่ได้ Auto-Deploy แทน workflow 1. ดู `SIMULATOR-LAB.md`
3. **`.github/workflows/build-ios.yml`** — Build unsigned **physical iPhone `.ipa`** (สำหรับ Sideloadly), ไม่ใช่ Simulator ZIP. สำหรับติดตั้งเครื่องจริงภายหลัง; ไม่ auto-install

### Windows files ของเดิม (ถูก ignore ไม่ Push ขึ้น Git)

```text
artifacts/BloubAvatarLab-v4-original-morph-verified.ipa
artifacts/Bloub-circle-to-triangle-original-2s.gif
artifacts/simulator-lab/Bloub-Appetize-Ready.zip
artifacts/simulator-lab/Bloub-Simulator-Test.mp4
artifacts/simulator-lab/Bloub-Simulator-Home.png
artifacts/simulator-lab/Bloub-XCTest-Log.txt
artifacts/simulator-lab/Bloub-Native-Simulator-Evidence.zip
START-SIMULATOR-LAB.cmd
```

- `BloubAvatarLab-v4-original-morph-verified.ipa` = **อุปกรณ์จริง**, ผู้ใช้ยืนยันว่า v4 ใช้ได้บน iPhone; **รักษาไฟล์นี้ไว้**
- `Bloub-Appetize-Ready.zip` = **Simulator app** เก่าที่เคยอัปโหลดเอง; **ปัจจุบันไม่จำเป็นต้องอัปโหลดเอง** เพราะ Auto-Deploy ผ่านแล้ว
- GitHub workflow artifacts อยู่ 7 วันเท่านั้น จึงควรรักษา local IPA, source code และหลักฐานสำคัญ
- `START-SIMULATOR-LAB.cmd` เปิด CI workflow และ video/folder ที่ดาวน์โหลดไว้บน Windows

## 4) สิ่งที่ทดสอบและยืนยันแล้ว

| รายการ | ผล |
| --- | --- |
| Native iPhone physical-device v4 | ผู้ใช้ยืนยันว่าใช้งานได้ (ก่อนติดตั้ง Appetize) |
| iPhone IPA build | GitHub Actions run [40816030466](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40816030466): success |
| Native Simulator lab | GitHub Actions run [40816546656](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40816546656): success; SwiftUI XCTest launch + morph-on-Home scenario ทดสอบจริง |
| Appetize interactive | ผู้ใช้อัปโหลด Simulator ZIP เองครั้งแรกและยืนยันว่า Appetize เปิด/กดทดลองได้; แต่ cloud streaming กระตุก |
| **Appetize Auto-Deploy** | [run 40847983431](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40847983431): token check **success**, ARM64 build **success**, app/extensions validation **success**, GitHub ZIP upload **success**, Appetize upload step **success** |
| GitHub Secret | **`APPETIZE_API_TOKEN` ตั้งค่าแล้วและ CI preflight ยืนยันผ่าน**; ห้ามอ่าน/คัดลอกค่าในแชตหรือ source |

Auto-Deploy success ครั้งแรก build จาก source commit `18b9006eb067e4c693d44f0deea7a56f5dec1760` (ก่อน commit คู่มือส่งต่องานฉบับนี้). โครงสร้างสำหรับ GitHub Pages / HTML mockup **ไม่ใช่โปรแกรมเป้าหมาย**.

## 5) การทำงานใน Session ถัดไป — ปฏิบัติจริง

1. เปิด repo ข้างต้นใน Windows แล้วตรวจ `git status` + `git log -1` (อย่าเดา commit/current state) ก่อนแก้โค้ด
2. ถ้าผู้ใช้ขอปรับหน้าตาหรือ animation ให้แก้ไฟล์ native ใน `BloubIsland/`, `BloubIslandWidget/`, `BloubNotificationContent/` และ `Shared/` เท่านั้นตามความจำเป็น; อย่าสร้างเว็บจำลองมาแทน
3. ทำการตรวจโค้ด / `git diff --check` / สถานะ Git แล้ว Commit+**Push `main`**. **Push เป็นเหตุให้ Auto-Deploy ทำงาน** เมื่อ path match; local edit หรือ commit เฉย ๆ ไม่อัปเดต Appetize
4. ตรวจ `Bloub Auto-Deploy to Appetize` run ใหม่จน **Build + Upload success** จริง; ห้ามบอกว่าขึ้น Appetize แล้วหาก workflow ยังทำงานหรือล้มเหลว
5. ให้ผู้ใช้เปิด https://appetize.io/apps/ios/com.bloub.island.poc → **Start Session ใหม่** เพื่อดู Build ล่าสุด (ไม่ต้องอัปโหลด ZIP, ไม่ต้องลง iPhone, ไม่ต้องเชื่อม Secret ซ้ำ)
6. หากอยากได้วิดีโอ XCTest/Screenshot จาก Simulator จริง ให้รัน `simulator-lab.yml` แยกตามความจำเป็น แล้วดาวน์โหลด artifacts บน Windows
7. เมื่อผ่าน milestone และต้องตรวจ hardware behavior ค่อยใช้ `build-ios.yml` + Sideloadly สำหรับ iPhone 16 Pro; คำนึงถึง free Apple ID signing limits

## 6) สิ่งที่ยังไม่ได้ทำ / ข้อจำกัด / ระวัง

- **ยังไม่มี AI Agent backend หรือ API เชื่อมกับ bot จริง** — เป็น UI/animation ทดลองเท่านั้น
- **iPhone 16 Pro** คือ hardware เป้าหมาย; `simulator-lab.yml` **ตั้งให้เลือก iPhone 16 Pro เป็นอันดับแรกแล้ว** โดย fallback ไปอุปกรณ์ที่ Runner มีหากไม่มี 16 Pro
- ไม่ได้ยืนยันว่า Dynamic Island เล่น 24 frames ได้ลื่นจริง; iOS อาจ throttle/coalesce ActivityKit. ต้องเก็บ screenshot/video/ทดสอบเครื่องจริงเพื่อยืนยัน
- Appetize cloud simulation อาจ **กระตุก**; ไม่มี native Appetize Windows simulator desktop ที่ช่วยตัดการสตรีม; วิดีโอจาก GitHub CI ดูย้อนหลังลื่นกว่า
- Appetize free-plan ใช้ session minutes จำกัด; GitHub public repo มีความเสี่ยงหากใส่ความลับหรือไฟล์ส่วนตัวโดยไม่ตั้งใจ
- **GitHub Repository Secret ชื่อ `APPETIZE_API_TOKEN` มีแล้ว** — อย่าให้ผู้ใช้สร้างใหม่โดยไม่มีเหตุ และ **ห้าม Push เนื้อหา Token** หรือไฟล์ `.txt` ที่เป็น credential
- ระบบ Auto-Deploy ไม่ทำงานเมื่อแก้ไฟล์นอก `paths:` ที่ระบุ เช่น update docs อย่างเดียว; Manual **Run workflow** ใช้ได้
- การเคลียร์แคชก่อนหน้า: ย้าย ZIP ซ้ำ 2 ไฟล์ไป quarantine กู้คืนได้ (ไม่ใช่ลบถาวร); มี archive ขนาดใหญ่บางส่วนยังอยู่ ตรวจสอบ SHA ก่อนลบ อย่าลบ source/IPA/หลักฐานโดยไม่ตรวจ
- หากเห็นเอกสารเดิมที่บอกว่า `Appetize ยังไม่เชื่อม` ให้ยึด **Auto-Deploy #2 success** และไฟล์ handoff ฉบับนี้เป็นสถานะล่าสุด

## 7) คู่มือที่เกี่ยวข้อง

- [README.md](README.md): animation v4 และวิธีทดสอบแต่ละ iOS surface
- [AUTO-DEPLOY.md](AUTO-DEPLOY.md): Auto-Deploy + Secret + GitHub Action + แก้ปัญหา
- [SIMULATOR-LAB.md](SIMULATOR-LAB.md): headless native Simulator, XCTest, video & artifacts
- [ULTIMATE-LAB.md](ULTIMATE-LAB.md): 38 effects, 4 modes, system control/widget experiments, limitations and sources
- [IPHONE-16PRO-TEST.md](IPHONE-16PRO-TEST.md): verified device IPA, Sideloadly, hands-on hardware checklist, pass/fail and safety
- [project.yml](project.yml): XcodeGen targets, Bundle ID, iOS deployment target

## 8) ข้อความเริ่ม Session ใหม่ (คัดลอกได้เลย)

> ทำโปรเจกต์ Bloub native iOS ต่อจากเดิม เปิด repository `teejutazing-cmd/bloub-island-poc` และอ่าน `SESSION-HANDOFF.md`, `AUTO-DEPLOY.md`, `SIMULATOR-LAB.md` และ `README.md` ก่อน จากนั้นตรวจสภาพจริงของ repo/Actions/Appetize. อย่าติดตั้งหรือสร้างระบบใหม่โดยไม่จำเป็น. แก้ native SwiftUI/ActivityKit/WidgetKit แล้ว Push `main` เพื่อ Auto-Deploy ไป Appetize ที่ `https://appetize.io/apps/ios/com.bloub.island.poc`. อุปกรณ์ปลายทาง iPhone 16 Pro, ทำงานบน Windows, ยังไม่เชื่อม AI Agent จริง. เริ่มจากคำสั่งงานถัดไปของฉัน.
