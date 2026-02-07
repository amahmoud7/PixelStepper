import Foundation
import Combine

/// Manages daily history tracking for 7-Day Memory UI and Phase Decay.
@MainActor
class HistoryManager: ObservableObject {
    /// Shared instance.
    static let shared = HistoryManager()
    
    /// Daily step goal (matches AvatarLogic thresholds).
    let dailyGoal = 7500
    
    /// Current day's goal state.
    @Published var todayState: DailyGoalState?
    
    /// Full 30-day history.
    @Published var history: DailyHistory
    
    /// Persistence manager.
    private let persistence = PersistenceManager.shared
    
    /// Cancellable for day change notifications.
    private var dayChangeCancellable: AnyCancellable?
    
    /// Date of last processed day (to detect day changes).
    private var lastProcessedDay: String
    
    private init() {
        // Load history from persistence
        self.history = persistence.dailyHistory ?? DailyHistory.createNew()
        
        // Initialize today state
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.lastProcessedDay = formatter.string(from: Date())
        self.todayState = history.state(for: Date())
        
        // Setup day change monitoring
        setupDayChangeMonitoring()
        
        // Initial refresh
        refreshHistory()
    }
    
    // MARK: - Public API
    
    /// Updates today's step count.
    func updateToday(steps: Int) {
        history.updateToday(steps: steps)
        todayState = history.state(for: Date())
        
        // Persist
        persistence.saveDailyHistory(history)
        
        // Update shared data
        SharedData.saveDailyHistory(history)
    }
    
    /// Records a complete day (for backfill scenarios).
    func recordDay(date: Date, steps: Int) {
        let day = DailyGoalState.create(for: date, steps: steps, goal: dailyGoal)
        history.recordDay(day)
        
        if Calendar.current.isDateInToday(date) {
            todayState = day
        }
        
        persistence.saveDailyHistory(history)
        SharedData.saveDailyHistory(history)
    }
    
    /// Refreshes history and handles day changes.
    func refreshHistory() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Check if day changed
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDayString = formatter.string(from: now)
        
        if currentDayString != lastProcessedDay {
            // Day changed - ensure yesterday is finalized
            finalizePreviousDay()
            lastProcessedDay = currentDayString
        }
        
        // Update today state
        if todayState == nil || !calendar.isDate(todayState!.date, inSameDayAs: today) {
            // New day - create fresh state
            let newToday = DailyGoalState.create(for: today, steps: 0, goal: dailyGoal)
            history.recordDay(newToday)
            todayState = newToday
        }
        
        // Persist
        persistence.saveDailyHistory(history)
        SharedData.saveDailyHistory(history)
    }
    
    /// Gets the last 7 days for week memory view.
    func last7Days() -> [DailyHistory.DayViewData] {
        return history.weekViewData()
    }
    
    /// Gets consecutive missed goal count.
    var consecutiveMisses: Int {
        return history.countConsecutiveMisses()
    }
    
    /// Backfills missing days with placeholder data.
    /// Call when app has been killed for several days.
    func backfillMissingDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Look back up to 30 days
        for dayOffset in -30...(-1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            if history.state(for: date) == nil {
                // Missing day - create placeholder
                // For new users, treat as 0 steps (neutral)
                // For existing users, we could estimate but 0 is safer
                let placeholder = DailyGoalState.create(for: date, steps: 0, goal: dailyGoal)
                history.recordDay(placeholder)
            }
        }
        
        persistence.saveDailyHistory(history)
        SharedData.saveDailyHistory(history)
    }
    
    /// Gets goal status for a specific date.
    func goalStatus(for date: Date) -> GoalStatus {
        guard let day = history.state(for: date) else {
            return .unknown
        }
        
        return day.isGoalMet ? .met : .missed
    }
    
    /// Reset history (for testing).
    func reset() {
        history = DailyHistory.createNew()
        todayState = nil
        persistence.saveDailyHistory(history)
    }
    
    /// Check if this is a new user (no history).
    var isNewUser: Bool {
        history.days.isEmpty
    }
    
    // MARK: - Private
    
    private func setupDayChangeMonitoring() {
        // Listen for significant time changes (day boundary)
        dayChangeCancellable = NotificationCenter.default
            .publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleDayChange()
            }
    }
    
    private func handleDayChange() {
        finalizePreviousDay()
        refreshHistory()
        
        // Notify phase decay manager
        PhaseDecayManager.shared.handleDayChange()
    }
    
    private func finalizePreviousDay() {
        // Ensure yesterday's data is preserved as-is
        // Steps will no longer update for yesterday
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        
        // Nothing special needed - steps won't be updated for past dates
        // Just persist current state
        persistence.saveDailyHistory(history)
    }
}

/// Goal status for a specific day.
enum GoalStatus: Equatable {
    case met
    case missed
    case unknown
    
    var color: String {
        switch self {
        case .met: return "#34C759"
        case .missed: return "#FF3B30"
        case .unknown: return "#8E8E93"
        }
    }
}

// MARK: - SharedData Extension

extension SharedData {
    private static let dailyHistoryKey = "dailyHistory"
    
    static func saveDailyHistory(_ history: DailyHistory) {
        guard let defaults = userDefaults else { return }
        
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: dailyHistoryKey)
        } catch {
            print("Failed to encode daily history: \(error)")
        }
    }
    
    static func loadDailyHistory() -> DailyHistory? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: dailyHistoryKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(DailyHistory.self, from: data)
        } catch {
            print("Failed to decode daily history: \(error)")
            return nil
        }
    }
}
