import XCTest

// iOS runs ActivityKit outside the foreground app. These tests deliberately
// assert app control/status and background execution, NOT a guaranteed
// expanded-Island pop (that presentation belongs to iOS).
final class BloubSimulatorUITests: XCTestCase {
    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testIslandOnlyControlsExistAndNoBannerButtons() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Dynamic Island Alert Lab"].waitForExistence(timeout: 25))
        XCTAssertTrue(app.buttons["island-start"].exists)
        XCTAssertTrue(app.buttons["island-alert-approval"].exists)
        XCTAssertTrue(app.buttons["island-alert-error"].exists)
        XCTAssertTrue(app.buttons["island-alert-complete"].exists)
        XCTAssertTrue(app.buttons["island-alert-silent"].exists)
        XCTAssertFalse(app.buttons["Instant banner (2s)"].exists)
        capture("01-island-only-controls")
    }

    func testIslandAlertCanBeArmedFromMainScreen() {
        let app = XCUIApplication()
        app.launch()
        let button = app.buttons["island-alert-approval"]
        XCTAssertTrue(button.waitForExistence(timeout: 25))
        button.tap()
        let countdown = app.staticTexts["island-countdown"]
        XCTAssertTrue(countdown.waitForExistence(timeout: 7))
        capture("02-island-alert-armed")
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 11)
        capture("03-island-alert-after-home")
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.springboard").exists)
    }

    func testAutomaticIslandAlertOnHomeForScreenRecording() {
        let app = XCUIApplication()
        app.launchArguments = ["--bloub-sim-island-popup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Dynamic Island Alert Lab"].waitForExistence(timeout: 25))
        Thread.sleep(forTimeInterval: 3)
        XCUIDevice.shared.press(.home)
        capture("04-home-before-live-alert")
        Thread.sleep(forTimeInterval: 10)
        capture("05-home-after-live-activity-alert")
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.springboard").exists)
    }
}
