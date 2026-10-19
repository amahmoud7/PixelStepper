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
}
