import Foundation

/// Tracks daily goal achievement for a single day.
/// Used for Phase Decay system and 7-Day Memory UI.
struct DailyGoalState: Codable, Equatable, Identifiable {
    /// Unique identifier (date string YYYY-MM-DD).
    var id: String { dateString }
    
    /// Date string in YYYY-MM-DD format.
    let dateString: String
    
    /// Actual date for calculations.
    let date: Date
    
    /// Steps taken on this day.
    var steps: Int
    
    /// Daily step goal (default 7500).
    var goal: Int
    
    /// Whether the goal was met.
    var isGoalMet: Bool
    
    /// Creates a new daily goal state.
    static func create(for date: Date, steps: Int = 0, goal: Int = 7500) -> DailyGoalState {
        DailyGoalState(
            dateString: dayKey(for: date),
            date: date,
            steps: steps,
            goal: goal,
            isGoalMet: steps >= goal
        )
    }
    
    /// Updates steps and recalculates goal status.
    mutating func updateSteps(_ newSteps: Int) {
        steps = newSteps
        isGoalMet = newSteps >= goal
    }
    
    /// Shared "yyyy-MM-dd" formatter. Creating DateFormatters is expensive and this runs in loops.
    /// Fixed Gregorian/POSIX so keys don't change with the user's calendar or numbering system.
    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Day key used for history, missions and step moments. Main-thread callers only.
    static func dayKey(for date: Date) -> String {
        if dayKeyFormatter.timeZone != TimeZone.current {
            dayKeyFormatter.timeZone = .current
        }
        return dayKeyFormatter.string(from: date)
    }
}

// MARK: - Daily Goal Extensions

extension DailyGoalState {
    /// Progress toward goal (0.0 to 1.0, can exceed 1.0).
    var progress: Double {
        Double(steps) / Double(goal)
    }
}
