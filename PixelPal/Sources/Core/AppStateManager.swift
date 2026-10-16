import SwiftUI
import Combine
import StoreKit

/// Centralized state manager replacing scattered @State in ContentView.
/// Single source of truth for avatar, steps, phase, streak, and all app state.
@MainActor
class AppStateManager: ObservableObject {
    // MARK: - Published State

    @Published var avatarState: AvatarState = .low
    @Published var gender: Gender = .male
    @Published var currentPhase: Int = 1
    @Published var cumulativeSteps: Int = 0
    @Published var weeklySteps: Int = 0
    @Published var currentStreak: Int = 0
    @Published var showPaywall: Bool = false
    @Published var showShareSheet: Bool = false
    @Published var showCelebration: CelebrationEvent?
    @Published var showStepMoment: Bool = false
    @Published var stepCoinToast: Int?

    // MARK: - Managers

    let liveActivityManager = LiveActivityManager()
    let storeManager = StoreManager.shared
    let celebrationManager = CelebrationManager()
    let missionManager = MissionManager()
    let stepMomentManager = StepMomentManager()
    let cosmeticManager = CosmeticManager()

    var currentLoadout: CosmeticLoadout {
        cosmeticManager.currentLoadout
    }

    // MARK: - Private

    private var previousPhase: Int = 1
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        // Forward nested ObservableObject changes so SwiftUI views update
        liveActivityManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    // MARK: - Computed

    var isOnboardingComplete: Bool {
        PersistenceManager.shared.userProfile != nil
    }

    var shareCardData: ShareCardData {
        ShareCardData(
            todaySteps: PersistenceManager.shared.progressState.todaySteps,
            weeklySteps: weeklySteps,
            avatarState: avatarState,
            gender: gender,
            currentPhase: currentPhase,
            isPremium: storeManager.isPremium,
            weekDays: HistoryManager.shared.last7Days()
        )
    }

    // MARK: - Setup

    func loadSavedData() {
        if let profile = PersistenceManager.shared.userProfile {
            gender = profile.selectedGender
        } else if let savedGender = SharedData.loadGender() {
            gender = savedGender
        }

        let progress = PersistenceManager.shared.progressState
        currentPhase = progress.currentPhase
        previousPhase = progress.currentPhase
        cumulativeSteps = progress.totalStepsSinceStart

        let weekData = SharedData.loadWeekData()
        weeklySteps = weekData.reduce(0, +)
        avatarState = SharedData.loadState()
        currentStreak = HistoryManager.shared.currentStreak
        updateStreakPersistence()

        // Load missions for today
        missionManager.loadOrGenerateMissions(weeklyAverage: weeklySteps / 7)
    }

    func fetchCumulativeSteps(healthManager: HealthKitManager) {
        guard PersistenceManager.shared.userProfile != nil else { return }

        // Invalidate cache so we always get a fresh query with the correct baseline
        healthManager.invalidateCache()

        // Use a far-back date to capture all HealthKit history, not just since profile creation.
        // This ensures cumulative steps survive reinstalls and updates.
        let allTimeStart = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()

        Task {
            let fetched = await healthManager.fetchCumulativeStepsAsync(since: allTimeStart)
            await MainActor.run {
                // Never regress — take the max of fetched and persisted
                let persisted = PersistenceManager.shared.progressState.totalStepsSinceStart
                cumulativeSteps = max(fetched, persisted)
                checkPhaseGraduation()
            }
        }
    }

    // MARK: - State Updates

    func updateState(healthManager: HealthKitManager) {
        let steps = healthManager.currentSteps
        let newState = AvatarLogic.determineState(steps: steps)
        let previousTodaySteps = PersistenceManager.shared.progressState.todaySteps

        avatarState = newState
        SharedData.saveState(state: newState, steps: steps, phase: currentPhase)
        SharedData.saveCumulativeSteps(cumulativeSteps)

        let historyManager = HistoryManager.shared
        historyManager.updateToday(steps: Int(steps))
        let weekDays = historyManager.last7Days()
        let weekStepArray = weekDays.map { $0.steps }
        SharedData.saveWeekData(weekStepArray)

        weeklySteps = weekStepArray.reduce(0, +)
        checkPhaseGraduation()

        let todaySteps = Int(steps)
        PersistenceManager.shared.updateProgress { progress in
            progress.todaySteps = todaySteps
            progress.totalStepsSinceStart = self.cumulativeSteps
        }

        updateStreakPersistence()

        // Update missions
        let previouslyCompleted = Set(missionManager.missions.filter(\.isCompleted).map(\.id))
        missionManager.updateProgress(
            todaySteps: todaySteps,
            currentStreak: currentStreak,
            currentHour: Calendar.current.component(.hour, from: Date())
        )
        // Award coins for newly completed missions
        for mission in missionManager.missions where mission.isCompleted && !previouslyCompleted.contains(mission.id) {
            awardCoins(mission.coinReward)
        }

        // Update weekly challenge
        updateWeeklyChallengeProgress(todaySteps: todaySteps)

        // Check for celebrations
        checkCelebrations(todaySteps: todaySteps, previousTodaySteps: previousTodaySteps)

        // Update personal records
        updatePersonalRecords(todaySteps: todaySteps)

        if liveActivityManager.isActive {
            liveActivityManager.updateActivity(
                steps: todaySteps,
                state: newState,
                gender: gender,
                phase: currentPhase,
                cumulativeSteps: cumulativeSteps
            )
        }

        // Schedule streak-at-risk notification with real data
        let stepsRemaining = max(0, 7500 - todaySteps)
        NotificationManager.shared.scheduleStreakAtRisk(streak: currentStreak, stepsRemaining: stepsRemaining)
    }

    func backfillWeeklyHistory(from dailyMap: [Date: Int], healthManager: HealthKitManager) {
        guard !dailyMap.isEmpty else { return }

        let historyManager = HistoryManager.shared
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        for dayOffset in (-6)...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            let dayStart = calendar.startOfDay(for: date)

            if let steps = dailyMap[dayStart], steps > 0 {
                if dayOffset < 0 {
                    historyManager.recordDay(date: dayStart, steps: steps)
                } else {
                    let currentTodaySteps = Int(healthManager.currentSteps)
                    if steps > currentTodaySteps {
                        historyManager.updateToday(steps: steps)
                    }
                }
            }
        }

        let weekDays = historyManager.last7Days()
        let weekStepArray = weekDays.map { $0.steps }
        SharedData.saveWeekData(weekStepArray)
        weeklySteps = weekStepArray.reduce(0, +)
        checkPhaseGraduation()
    }

    // MARK: - Private Helpers

    private func updateWeeklyChallengeProgress(todaySteps: Int) {
        guard let challenge = missionManager.weeklyChallenge, !challenge.isCompleted else { return }

        let weekData = HistoryManager.shared.history.weekViewData()
        let activeDays = weekData.filter { $0.isGoalMet }.count
        let bestDay = weekData.map(\.steps).max() ?? todaySteps

        let wasCompleted = challenge.isCompleted
        missionManager.updateWeeklyProgress(
            weeklySteps: weeklySteps,
            activeDaysThisWeek: activeDays,
            bestDayThisWeek: bestDay
        )

        // Award coins if just completed
        if let updated = missionManager.weeklyChallenge, updated.isCompleted && !wasCompleted {
            awardCoins(updated.coinReward)
            celebrationManager.tryTrigger(.dailyGoalMet(steps: todaySteps))
        }
    }

    private func updateStreakPersistence() {
        let streak = HistoryManager.shared.currentStreak
        currentStreak = streak
        let progress = PersistenceManager.shared.progressState
        if streak != progress.currentStreak || streak > progress.longestStreak {
            PersistenceManager.shared.updateProgress { state in
                state.currentStreak = streak
                if streak > state.longestStreak {
                    state.longestStreak = streak
                }
            }
        }
    }

    private func checkPhaseGraduation() {
        let entitlements = PersistenceManager.shared.entitlements
        let phaseFromWeekly = PhaseCalculator.currentPhase(
            totalSteps: weeklySteps,
            isPremium: entitlements.isPremium
        )

        guard phaseFromWeekly > currentPhase else { return }

        let oldPhase = currentPhase
        currentPhase = phaseFromWeekly

        PersistenceManager.shared.updateProgress { progress in
            progress.totalStepsSinceStart = self.cumulativeSteps
            progress.currentPhase = phaseFromWeekly
        }

        // Trigger phase evolution celebration
        celebrationManager.tryTrigger(.phaseEvolution(phase: phaseFromWeekly))
        if let event = celebrationManager.dequeueNext() {
            showCelebration = event
        }

        // Award coins for phase evolution
        awardCoins(250)

        if phaseFromWeekly == 2 && !entitlements.isPremium {
            let progress = PersistenceManager.shared.progressState
            if !progress.hasSeenPaywall {
                showPaywall = true
                PersistenceManager.shared.updateProgress { progress in
                    progress.hasSeenPaywall = true
                    progress.lastPaywallDate = Date()
                }
            }
        }
    }

    /// Asks for a rating on a happy moment (daily goal hit), never on top of the paywall.
    private func requestReviewIfEligible() {
        let progress = PersistenceManager.shared.progressState
        guard !progress.hasRequestedReview else { return }
        guard progress.currentPhase >= 2 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard !self.showPaywall else { return }
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            SKStoreReviewController.requestReview(in: windowScene)
            PersistenceManager.shared.updateProgress { progress in
                progress.hasRequestedReview = true
            }
        }
    }

    private func checkCelebrations(todaySteps: Int, previousTodaySteps: Int) {
        let dailyGoal = 7500

        // Daily goal met (first time today)
        if todaySteps >= dailyGoal && previousTodaySteps < dailyGoal {
            celebrationManager.tryTrigger(.dailyGoalMet(steps: todaySteps))
            awardCoins(25)
            requestReviewIfEligible()
        }

        // Streak milestones
        let streakMilestones = [7, 14, 30, 60, 100, 365]
        if streakMilestones.contains(currentStreak) {
            celebrationManager.tryTrigger(.streakMilestone(days: currentStreak))
            let coinReward = currentStreak >= 100 ? 500 : currentStreak >= 30 ? 300 : 100
            awardCoins(coinReward)

            // Re-engagement: show paywall on streak milestones for non-premium users
            tryPaywallReengagement()
        }

        // Re-engagement: show paywall when all daily missions completed (upsell "want 5?")
        if !storeManager.isPremium && missionManager.completedCount == missionManager.missions.count && missionManager.missions.count == 3 {
            tryPaywallReengagement()
        }

        // Show next queued celebration
        if showCelebration == nil, let event = celebrationManager.dequeueNext() {
            showCelebration = event
        }
    }

    /// Shows paywall for non-premium users with a 7-day cooldown to avoid spam.
    private func tryPaywallReengagement() {
        guard !storeManager.isPremium else { return }
        guard currentPhase >= 2 else { return }

        let progress = PersistenceManager.shared.progressState
        if let lastShown = progress.lastPaywallDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastShown, to: Date()).day ?? 0
            guard daysSince >= 7 else { return }
        }

        PersistenceManager.shared.updateProgress { state in
            state.lastPaywallDate = Date()
        }

        // Delay slightly so celebrations show first
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showPaywall = true
        }
    }

    private func updatePersonalRecords(todaySteps: Int) {
        let progress = PersistenceManager.shared.progressState
        if todaySteps > progress.bestDaySteps {
            PersistenceManager.shared.updateProgress { state in
                state.bestDaySteps = todaySteps
                state.bestDayDate = Date()
            }
            if todaySteps > 1000 {
                celebrationManager.tryTrigger(.personalRecord(type: "Best Day", value: todaySteps))
                awardCoins(150)
            }
        }

        // Cumulative step milestones
        if let milestone = MilestoneCalculator.checkMilestone(
            previousSteps: cumulativeSteps - todaySteps,
            currentSteps: cumulativeSteps
        ) {
            celebrationManager.tryTrigger(.stepMilestone(cumulative: milestone))
            let coinReward = milestone >= 100_000 ? 500 : milestone >= 50_000 ? 300 : 100
            awardCoins(coinReward)
        }
    }

    // MARK: - Coins

    func awardCoins(_ amount: Int) {
        let finalAmount = storeManager.isPremium ? amount * 2 : amount
        PersistenceManager.shared.updateProgress { state in
            state.stepCoinBalance += finalAmount
        }
        stepCoinToast = finalAmount
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.stepCoinToast = nil
        }
    }
}
