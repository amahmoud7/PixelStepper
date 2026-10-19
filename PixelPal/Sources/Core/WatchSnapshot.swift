import Foundation

/// What the iPhone shares with the Apple Watch app over WatchConnectivity.
/// Steps are read on the watch from HealthKit; this carries everything the watch can't know.
/// Compiled into both the iOS app and the watch app.
struct WatchSnapshot: Equatable {
    var gender: Gender
    var phase: Int
    var currentStreak: Int
    var longestStreak: Int
    var dailyGoal: Int
    var updatedAt: Date

    static let placeholder = WatchSnapshot(
        gender: .male, phase: 1, currentStreak: 0, longestStreak: 0, dailyGoal: 7500, updatedAt: .distantPast
    )

    /// 0...1 toward today's goal.
    func goalProgress(steps: Int) -> Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1, max(0, Double(steps) / Double(dailyGoal)))
    }

    // MARK: - Application context (property-list types only)

    private enum Key {
        static let gender = "gender"
        static let phase = "phase"
        static let currentStreak = "currentStreak"
        static let longestStreak = "longestStreak"
        static let dailyGoal = "dailyGoal"
        static let updatedAt = "updatedAt"
    }

    var dictionary: [String: Any] {
        [
            Key.gender: gender.rawValue,
            Key.phase: phase,
            Key.currentStreak: currentStreak,
            Key.longestStreak: longestStreak,
            Key.dailyGoal: dailyGoal,
            Key.updatedAt: updatedAt,
        ]
    }

    init(gender: Gender, phase: Int, currentStreak: Int, longestStreak: Int, dailyGoal: Int, updatedAt: Date) {
        self.gender = gender
        self.phase = phase
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.dailyGoal = dailyGoal
        self.updatedAt = updatedAt
    }

    init?(dictionary: [String: Any]) {
        guard let genderRaw = dictionary[Key.gender] as? String,
              let gender = Gender(rawValue: genderRaw),
              let phase = dictionary[Key.phase] as? Int,
              let currentStreak = dictionary[Key.currentStreak] as? Int,
              let longestStreak = dictionary[Key.longestStreak] as? Int,
              let dailyGoal = dictionary[Key.dailyGoal] as? Int,
              let updatedAt = dictionary[Key.updatedAt] as? Date else { return nil }
        self.init(
            gender: gender,
            phase: min(4, max(1, phase)),
            currentStreak: max(0, currentStreak),
            longestStreak: max(0, longestStreak),
            dailyGoal: dailyGoal,
            updatedAt: updatedAt
        )
    }
}
