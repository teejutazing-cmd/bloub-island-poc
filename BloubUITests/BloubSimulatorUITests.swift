import XCTest

// Runs against the actual Bloub SwiftUI app inside Apple's iOS Simulator.
// The morph test checks that app + SpringBoard work; it deliberately does NOT
// assert uninterrupted 12 FPS in Dynamic Island (iOS decides presentation).
final class BloubSimulatorUITests: XCTestCase {
    private func capture(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testUltimateLabOpensWithRealEffectControls() {
        let app = XCUIApplication()
        app.launch()
        let button = app.buttons["ultimate-open"]
        XCTAssertTrue(button.waitForExistence(timeout: 20), "Ultimate lab launch button missing")
        button.tap()
        XCTAssertTrue(app.navigationBars["Bloub Ultimate Lab"].waitForExistence(timeout: 15),
                      "Native Ultimate Lab must open")
        XCTAssertTrue(app.staticTexts["38 effects · 4 test modes · iPhone 16 Pro target"].exists)
        capture("04-ultimate-lab-running")
        let close = app.buttons["ultimate-close"]
        XCTAssertTrue(close.exists)
        close.tap()
        XCTAssertTrue(app.staticTexts["Avatar playground"].waitForExistence(timeout: 10))
    }

    func testNativeAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Avatar playground"].waitForExistence(timeout: 20),
                      "Native SwiftUI Bloub playground should launch")
        XCTAssertTrue(app.buttons["Start"].exists,
                      "ActivityKit control should be present")
        capture("01-bloub-app-launch")
    }

    func testOriginalSpriteMorphWhileAppIsBackgrounded() {
        let app = XCUIApplication()
        app.launchArguments = ["--bloub-sim-morph"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Avatar playground"].waitForExistence(timeout: 20),
                      "Native Bloub app should launch for the morph scenario")
        // Give app onAppear time to request Live Activity, then go Home.
        Thread.sleep(forTimeInterval: 3)
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 4)
        capture("02-home-before-morph")
        Thread.sleep(forTimeInterval: 10)
        capture("03-home-after-original-24-frame-morph")
        // This verifies the test ran on SpringBoard. It does not claim 24
        // rendered Dynamic Island frames; analysis of the video is manual.
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.springboard").exists)
    }
}
