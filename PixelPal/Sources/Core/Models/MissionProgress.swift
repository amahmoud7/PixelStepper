import Foundation

/// Pure mission progress rules, kept off the main actor so they're easy to test.
enum MissionProgress {
    struct Input {
        let todaySteps: Int
        /// Steps between midnight and noon (nil until HealthKit answers).
        let stepsBeforeNoon: Int?
        /// Steps since 17:00 today (nil before 17:00 or until HealthKit answers).
        let stepsSinceFivePM: Int?
        let currentHour: Int
        let dailyGoal: Int
    }

    /// New progress for `mission`. Progress never goes backwards.
    static func evaluate(_ mission: DailyMission, _ input: Input) -> Int {
        let current = mission.progress
        let next: Int
        switch mission.type {
        case .stepTarget, .goalCrush:
            next = input.todaySteps
        case .morningWalk:
            // Real morning total when known, so opening the app after noon still counts.
            next = input.stepsBeforeNoon ?? (input.currentHour < 12 ? input.todaySteps : current)
        case .eveningPush:
            guard input.currentHour >= 17 else { return current }
            next = input.stepsSinceFivePM ?? current
        case .streakExtend:
            next = input.todaySteps >= input.dailyGoal ? 1 : 0
        case .consistentDay:
            // Count active hours from 8:00; nothing before then.
            guard input.currentHour >= 8 else { return current }
            let activeHours = max(1, input.currentHour - 7)
            next = input.todaySteps / activeHours >= 500 ? activeHours : current
        }
        return max(current, min(next, mission.target))
    }
}
