import Foundation
import Combine

/// Manages daily history tracking (week view, calendar, streaks).
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
        var loaded = persistence.dailyHistory ?? DailyHistory.createNew()
        if loaded.normalizeDayKeys() {
            persistence.saveDailyHistory(loaded)
        }
        self.history = loaded
        
        // Initialize today state
        self.lastProcessedDay = DailyGoalState.dayKey(for: Date())
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
    }
    
    /// Records a complete day (for backfill scenarios).
    func recordDay(date: Date, steps: Int) {
        let day = DailyGoalState.create(for: date, steps: steps, goal: dailyGoal)
        history.recordDay(day)
        
        if Calendar.current.isDateInToday(date) {
            todayState = day
        }
        
        persistence.saveDailyHistory(history)
    }
    
    /// Refreshes history and handles day changes.
    func refreshHistory() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Check if day changed
        let currentDayString = DailyGoalState.dayKey(for: now)
        
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
    }
    
    /// Gets the last 7 days for week memory view.
    func last7Days() -> [DailyHistory.DayViewData] {
        return history.weekViewData()
    }
    
    /// Gets consecutive missed goal count.
    var consecutiveMisses: Int {
        return history.countConsecutiveMisses()
    }

    /// Gets current streak (consecutive days with goal met).
    /// Premium users get one streak freeze per week — one missed day is forgiven. Read-only.
    var currentStreak: Int {
        guard PersistenceManager.shared.entitlements.isPremium else {
            return history.countConsecutiveGoalsMet()
        }
        return StreakFreezePolicy.resolve(
            history: history,
            lastFreezeDate: PersistenceManager.shared.progressState.streakFreezeUsedDate
        ).streak
    }

    /// Records a newly used streak freeze. Call before reading `currentStreak` during updates.
    func applyStreakFreezeIfNeeded() {
        guard PersistenceManager.shared.entitlements.isPremium else { return }
        let result = StreakFreezePolicy.resolve(
            history: history,
            lastFreezeDate: PersistenceManager.shared.progressState.streakFreezeUsedDate
        )
        guard let frozenDate = result.freezeToRecord else { return }
        PersistenceManager.shared.updateProgress { $0.streakFreezeUsedDate = frozenDate }
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
    }
    
    private func finalizePreviousDay() {
        // Ensure yesterday's data is preserved as-is
        // Steps will no longer update for yesterday
        let calendar = Calendar.current
        guard calendar.date(byAdding: .day, value: -1, to: Date()) != nil else { return }
        
        // Nothing special needed - steps won't be updated for past dates
        // Just persist current state
        persistence.saveDailyHistory(history)
    }
}
