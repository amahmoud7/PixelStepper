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

        // Share sheet from Home's top bar.
        app.swipeDown()
        pause()
        let share = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'share'")).firstMatch
        if share.waitForExistence(timeout: 3) {
            share.tap()
            pause(2)
            snap("50-share")
            let done = app.buttons["Done"]
            if done.waitForExistence(timeout: 3) { done.tap() } else { app.swipeDown() }
            pause()
        }

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

    /// Marketing captures with demo data, named A1…A5 for the App Store compositor.
    func test_3_appStore() {
        let app = launch(["-UITestMode", "-UITestSkipOnboarding", "-UITestDemoData"])
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        pause(3)
        snap("A1-home")

        app.swipeUp()
        pause()
        snap("A3-missions")
        app.swipeDown()

        app.tabBars.buttons["Stats"].tap()
        pause(2)
        snap("A4-stats")

        // Paywall (no prices in demo mode): the four phase auras and what Premium adds.
        app.tabBars.buttons["Profile"].tap()
        pause()
        let upgrade = app.buttons["Upgrade"]
        if upgrade.waitForExistence(timeout: 3) {
            upgrade.tap()
            pause(2)
            snap("A5-premium")
            let close = app.buttons["Close"]
            if close.waitForExistence(timeout: 3) { close.tap() } else { app.swipeDown() }
            pause()
        }

        // Live Activity in the Dynamic Island: start it from Profile, then go to the Home Screen.
        let toggle = app.switches["Live Activity"]
        if toggle.waitForExistence(timeout: 3), toggle.isEnabled {
            toggle.tap()
            pause(2)
            XCUIDevice.shared.press(.home)
            pause(3)
            snap("A2-island")
        }
    }

    func test_4_appStoreEvolve() {
        _ = launch(["-UITestMode", "-UITestResetData"])
        pause()
        snap("A6-hook")
    }

    /// The largest accessibility text size, to catch clipping and broken layouts.
    func test_5_largeText() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-UITestSkipOnboarding", "-UITestDemoData",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        app.launch()
        pause(3)
        dismissSystemAlerts()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        snap("60-xl-home")
        app.swipeUp()
        pause()
        snap("61-xl-home-scrolled")
        app.tabBars.buttons["Stats"].tap()
        pause(2)
        snap("62-xl-stats")
        app.tabBars.buttons["Profile"].tap()
        pause()
        snap("63-xl-profile")
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
