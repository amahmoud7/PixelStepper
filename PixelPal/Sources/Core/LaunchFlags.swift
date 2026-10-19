import Foundation

/// Launch arguments used by the UI screenshot tests. Normal launches never pass them.
enum LaunchFlags {
    private static let arguments = ProcessInfo.processInfo.arguments

    /// Skips the splash and system permission prompts so screens can be captured deterministically.
    static let uiTest = arguments.contains("-UITestMode")
    /// Starts from a clean slate (shows onboarding).
    static let resetData = arguments.contains("-UITestResetData")
    /// Seeds a profile so the app opens straight into the tabs.
    static let skipOnboarding = arguments.contains("-UITestSkipOnboarding")
    /// Realistic sample data for App Store screenshots (no HealthKit in the simulator).
    static let demoData = arguments.contains("-UITestDemoData")

    enum Demo {
        static let todaySteps = 6_240
        static let streakDays = 12
        static let cumulativeSteps = 182_400
        /// Past days, oldest first (all at or above the 7,500 goal so the streak holds).
        static let pastDays = [8_120, 9_430, 7_980, 11_260, 8_640, 10_310, 7_720, 9_870, 12_540, 8_310, 9_120, 10_980]
    }
}
