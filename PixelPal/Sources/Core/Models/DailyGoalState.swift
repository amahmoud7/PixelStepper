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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        return DailyGoalState(
            dateString: formatter.string(from: date),
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
    
    /// Date formatter for converting date strings.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Daily Goal Extensions

extension DailyGoalState {
    /// Returns a color for UI display based on goal status.
    var statusColorName: String {
        isGoalMet ? "goalMet" : "goalMissed"
    }
    
    /// Progress toward goal (0.0 to 1.0, can exceed 1.0).
    var progress: Double {
        Double(steps) / Double(goal)
    }
}
