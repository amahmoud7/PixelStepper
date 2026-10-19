import Foundation

/// Launch arguments for CI screenshots (`simctl launch … -UITestDemoData -WatchPage 1`). Never passed normally.
enum WatchLaunch {
    private static let arguments = ProcessInfo.processInfo.arguments

    static let demoData = arguments.contains("-UITestDemoData")

    /// Initial page: 0 = Today, 1 = Streak.
    static var startPage: Int {
        guard let index = arguments.firstIndex(of: "-WatchPage"),
              arguments.indices.contains(index + 1),
              let page = Int(arguments[index + 1]) else { return 0 }
        return page
    }

    enum Demo {
        static let todaySteps = 6_240
        /// Oldest first; today last.
        static let week = [9_120, 8_310, 12_540, 9_870, 10_980, 7_720, 6_240]
        static let snapshot = WatchSnapshot(
            gender: .female, phase: 2, currentStreak: 12, longestStreak: 21, dailyGoal: 7500, updatedAt: Date()
        )
    }
}
