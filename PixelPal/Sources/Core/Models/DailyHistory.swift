import Foundation

/// Rolling history of daily goal states (long enough for year-long streaks).
/// Used for 7-Day Memory UI and Phase Decay tracking.
struct DailyHistory: Codable, Equatable {
    /// Maximum days to keep in history.
    static let maxDays = 400
    
    /// Array of daily goal states (oldest to newest).
    var days: [DailyGoalState]
    
    /// Date when history was last updated.
    var lastUpdated: Date
    
    /// Creates empty history.
    static func createNew() -> DailyHistory {
        DailyHistory(
            days: [],
            lastUpdated: Date()
        )
    }
    
    /// Adds or updates a day in history.
    mutating func recordDay(_ day: DailyGoalState) {
        // Remove existing entry for same date if present
        days.removeAll { $0.dateString == day.dateString }
        
        // Add new day
        days.append(day)
        
        // Sort by date
        days.sort { $0.date < $1.date }
        
        // Trim to max days
        if days.count > Self.maxDays {
            days = Array(days.suffix(Self.maxDays))
        }
        
        lastUpdated = Date()
    }
    
    /// Repairs day keys written by older builds that keyed days with the user's calendar or
    /// numbering system. Valid "yyyy-MM-dd" keys are the source of truth and are never touched,
    /// so time-zone travel can't shift history. Returns true when anything changed.
    mutating func normalizeDayKeys() -> Bool {
        guard days.contains(where: { !Self.isValidDayKey($0.dateString) }) else { return false }
        var byKey: [String: DailyGoalState] = [:]
        for day in days {
            let key = Self.isValidDayKey(day.dateString) ? day.dateString : DailyGoalState.dayKey(for: day.date)
            let normalized = DailyGoalState(
                dateString: key, date: day.date, steps: day.steps, goal: day.goal, isGoalMet: day.isGoalMet
            )
            if let existing = byKey[key], existing.steps >= normalized.steps { continue }
            byKey[key] = normalized
        }
        days = byKey.values.sorted { $0.dateString < $1.dateString }
        return true
    }

    /// ASCII "yyyy-MM-dd" with a plausible Gregorian year.
    static func isValidDayKey(_ key: String) -> Bool {
        let parts = key.split(separator: "-")
        guard key.count == 10, parts.count == 3,
              key.allSatisfy({ $0 == "-" || ("0"..."9").contains($0) }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return false }
        return (2000...2200).contains(year) && (1...12).contains(month) && (1...31).contains(day)
    }

    /// Day key → state, for loops that look up many days (streaks span up to `maxDays`).
    private func indexByDay() -> [String: DailyGoalState] {
        Dictionary(days.map { ($0.dateString, $0) }, uniquingKeysWith: { _, latest in latest })
    }

    /// Gets the state for a specific date.
    func state(for date: Date) -> DailyGoalState? {
        let dateString = DailyGoalState.dayKey(for: date)
        return days.last { $0.dateString == dateString }
    }
    
    /// Gets today's state (creates if missing).
    mutating func getOrCreateToday(goal: Int = 7500) -> DailyGoalState {
        let today = Date()
        if let existing = state(for: today) {
            return existing
        }
        
        let newDay = DailyGoalState.create(for: today, goal: goal)
        recordDay(newDay)
        return newDay
    }
    
    /// Updates today's step count.
    mutating func updateToday(steps: Int) {
        let today = Date()
        let dateString = DailyGoalState.dayKey(for: today)
        
        if let index = days.firstIndex(where: { $0.dateString == dateString }) {
            days[index].updateSteps(steps)
        } else {
            let newDay = DailyGoalState.create(for: today, steps: steps)
            recordDay(newDay)
        }
        
        lastUpdated = Date()
    }
    
    /// Gets the last 7 days for the week memory view.
    /// Returns 6 past days + today (or partial if less history exists).
    func last7Days() -> [DailyGoalState] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var result: [DailyGoalState] = []
        
        // Build 7-day window (6 past + today)
        for dayOffset in (-6)...0 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                if let day = state(for: date) {
                    result.append(day)
                } else {
                    // Create placeholder for missing day
                    let placeholder = DailyGoalState.create(for: date, steps: 0, goal: 7500)
                    result.append(placeholder)
                }
            }
        }
        
        return result
    }
    
    /// Counts consecutive missed goals working backward from today.
    func countConsecutiveMisses() -> Int {
        let index = indexByDay()
        func state(for date: Date) -> DailyGoalState? { index[DailyGoalState.dayKey(for: date)] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var consecutiveMisses = 0
        
        // Check yesterday and earlier (going backwards)
        for dayOffset in stride(from: -1, through: -Self.maxDays, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { break }
            
            if let day = state(for: date) {
                if day.isGoalMet {
                    // Found a goal met, stop counting
                    break
                } else {
                    consecutiveMisses += 1
                }
            } else {
                // No data for this day - treat as incomplete/miss for decay calculation
                // This handles app-killed-for-days scenario
                consecutiveMisses += 1
            }
        }
        
        return consecutiveMisses
    }
    
    /// Checks if goal was met on a specific date.
    func wasGoalMet(on date: Date) -> Bool {
        return state(for: date)?.isGoalMet ?? false
    }

    /// Counts consecutive days with goal met, ending at yesterday (today is still in progress).
    func countConsecutiveGoalsMet() -> Int {
        let index = indexByDay()
        func state(for date: Date) -> DailyGoalState? { index[DailyGoalState.dayKey(for: date)] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0

        // Start from yesterday and walk backward
        for dayOffset in stride(from: -1, through: -Self.maxDays, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { break }

            if let day = state(for: date), day.isGoalMet {
                streak += 1
            } else {
                break
            }
        }

        // Also count today if goal already met
        if let todayState = state(for: today), todayState.isGoalMet {
            streak += 1
        }

        return streak
    }

    /// Counts consecutive days with goal met, allowing one missed day to be "frozen."
    /// Returns the streak count and the date that was frozen (if any).
    func countConsecutiveGoalsMetWithFreeze() -> (streak: Int, frozenDate: Date?) {
        let index = indexByDay()
        func state(for date: Date) -> DailyGoalState? { index[DailyGoalState.dayKey(for: date)] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var frozenDate: Date?

        // Start from yesterday and walk backward
        for dayOffset in stride(from: -1, through: -Self.maxDays, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { break }

            if let day = state(for: date), day.isGoalMet {
                streak += 1
            } else if frozenDate == nil {
                // Use streak freeze on this missed day
                frozenDate = date
                streak += 1
            } else {
                break
            }
        }

        // Also count today if goal already met
        if let todayState = state(for: today), todayState.isGoalMet {
            streak += 1
        }

        return (streak, frozenDate)
    }
}

// MARK: - Week View Helpers

extension DailyHistory {
    /// Data for a single day in the week view.
    struct DayViewData: Identifiable, Equatable {
        var id: Date { date }
        let date: Date
        let isToday: Bool
        let isGoalMet: Bool
        let steps: Int
        let hasData: Bool
        
        static func == (lhs: DayViewData, rhs: DayViewData) -> Bool {
            lhs.date == rhs.date &&
            lhs.isToday == rhs.isToday &&
            lhs.isGoalMet == rhs.isGoalMet &&
            lhs.steps == rhs.steps &&
            lhs.hasData == rhs.hasData
        }
    }
    
    /// Gets formatted data for the 7-day memory UI.
    func weekViewData() -> [DayViewData] {
        let last7 = last7Days()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return last7.map { day in
            let dayDate = calendar.startOfDay(for: day.date)
            return DayViewData(
                date: day.date,
                isToday: dayDate == today,
                isGoalMet: day.isGoalMet,
                steps: day.steps,
                hasData: day.steps > 0 || dayDate == today
            )
        }
    }
}
