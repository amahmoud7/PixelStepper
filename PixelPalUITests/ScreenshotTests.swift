import XCTest

/// Captures every main screen so the UI can be reviewed from CI artifacts.
/// PNGs go to $SCREENSHOT_DIR (passed as TEST_RUNNER_SCREENSHOT_DIR) and are also attached to the result bundle.
final class ScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    func test_1_onboarding() {
        let app = launch(["-UITestMode", "-UITestResetData"])
        snap("01-onboarding-1")

        // Walk forward through onboarding pages, capturing each one.
        // 3 pages; the character page needs a pick before its CTA appears, so allow a few taps.
        for page in 2...6 {
            if app.tabBars.firstMatch.exists { break }   // onboarding finished
            guard let next = primaryButton(in: app) else { break }
            next.tap()
            pause()
            dismissSystemAlerts()
            snap(String(format: "%02d-onboarding-%d", page, page))
        }
    }

    func test_2_mainTabs() {
        let app = launch(["-UITestMode", "-UITestSkipOnboarding"])
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        pause(2)
        snap("10-home")

        app.swipeUp()
        pause()
        snap("11-home-scrolled")

        app.tabBars.buttons["Stats"].tap()
        pause()
        snap("20-stats")
        app.swipeUp()
        pause()
        snap("21-stats-scrolled")

        app.tabBars.buttons["Profile"].tap()
        pause()
        snap("30-profile")
        app.swipeUp()
        pause()
        snap("31-profile-scrolled")

        // Profile's "Upgrade" row (free users), falling back to any premium entry point.
        var unlock = app.buttons["Upgrade"]
        if !unlock.waitForExistence(timeout: 3) {
            unlock = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'premium' OR label CONTAINS[c] 'upgrade'")).firstMatch
        }
        if unlock.waitForExistence(timeout: 3) {
            unlock.tap()
            pause(2)
            snap("40-paywall")
            app.swipeUp()
            pause()
            snap("41-paywall-scrolled")
        }
    }

    // MARK: - Helpers

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        pause(2)
        dismissSystemAlerts()
        return app
    }

    /// Permission alerts (notifications, Health) belong to SpringBoard and would cover the screenshots.
    private func dismissSystemAlerts() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Don’t Allow", "Don't Allow", "Not Now", "OK"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 1) {
                button.tap()
                pause(0.5)
            }
        }
    }

    /// The bottom-most enabled button (onboarding CTAs sit at the bottom of each page).
    private func primaryButton(in app: XCUIApplication) -> XCUIElement? {
        let buttons = app.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable && $0.isEnabled }
        return buttons.max { $0.frame.maxY < $1.frame.maxY }
    }

    private func pause(_ seconds: Double = 1) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func snap(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let env = ProcessInfo.processInfo.environment
        guard let dir = env["SCREENSHOT_DIR"], !dir.isEmpty else { return }
        let device = (env["SIMULATOR_DEVICE_NAME"] ?? "device").replacingOccurrences(of: " ", with: "_")
        let folder = URL(fileURLWithPath: dir, isDirectory: true).appendingPathComponent(device, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? screenshot.pngRepresentation.write(to: folder.appendingPathComponent("\(name).png"))
    }
}
