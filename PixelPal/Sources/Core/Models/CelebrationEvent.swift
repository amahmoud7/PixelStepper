import Foundation

/// Types of celebrations that trigger full-screen overlays.
enum CelebrationEvent: Equatable, Identifiable {
    case streakMilestone(days: Int)
    case phaseEvolution(phase: Int)
    case dailyGoalMet(steps: Int)
    case personalRecord(type: String, value: Int)
    case stepMilestone(cumulative: Int)
    case weeklyChallenge(title: String)

    var id: String {
        switch self {
        case .streakMilestone(let days): return "streak_\(days)"
        case .phaseEvolution(let phase): return "phase_\(phase)"
        case .dailyGoalMet(let steps): return "goal_\(steps)"
        case .personalRecord(let type, let value): return "record_\(type)_\(value)"
        case .stepMilestone(let cumulative): return "milestone_\(cumulative)"
        case .weeklyChallenge(let title): return "weekly_\(title)"
        }
    }

    var title: String {
        switch self {
        case .streakMilestone(let days): return "\(days)-Day Streak!"
        case .phaseEvolution(let phase): return "Phase \(phase) Unlocked!"
        case .dailyGoalMet: return "Goal Crushed!"
        case .personalRecord(let type, _): return "New \(type)!"
        case .stepMilestone(let cumulative): return "\(MilestoneCalculator.formatMilestone(cumulative)) Steps!"
        case .weeklyChallenge: return "Weekly Challenge Complete!"
        }
    }

    var subtitle: String {
        switch self {
        case .streakMilestone(let days): return "You've walked \(days) days in a row. Incredible!"
        case .phaseEvolution(let phase):
            let names = [1: "Seedling", 2: "Growing", 3: "Thriving", 4: "Legendary"]
            return "Your character evolved to \(names[phase] ?? "Unknown")!"
        case .dailyGoalMet(let steps): return "\(steps.formatted()) steps today. You did it!"
        case .personalRecord(_, let value): return "\(value.formatted()) steps - a new personal best!"
        case .stepMilestone(let cumulative): return "\(cumulative.formatted()) total steps and counting!"
        case .weeklyChallenge(let title): return "\(title): done. What a week!"
        }
    }

    var shareText: String {
        switch self {
        case .streakMilestone(let days): return "I just hit a \(days)-day streak on Pixel Stepper!"
        case .phaseEvolution(let phase): return "My character just evolved to Phase \(phase) on Pixel Stepper!"
        case .dailyGoalMet(let steps): return "Crushed my \(steps.formatted())-step goal on Pixel Stepper!"
        case .personalRecord(let type, let value): return "New \(type): \(value.formatted()) steps on Pixel Stepper!"
        case .stepMilestone(let cumulative): return "Just hit \(cumulative.formatted()) total steps on Pixel Stepper!"
        case .weeklyChallenge(let title): return "Completed the \(title) weekly challenge on Pixel Stepper!"
        }
    }
}
