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
    @Published var stepCoinToast: Int?

    /// Paywall requested while a celebration was on screen; shown after it's dismissed.
    var paywallAfterCelebration = false

    // MARK: - Managers

    let liveActivityManager = LiveActivityManager()
    let storeManager = StoreManager.shared
    let celebrationManager = CelebrationManager()
    let missionManager = MissionManager()
    let cosmeticManager = CosmeticManager()

    var currentLoadout: CosmeticLoadout {
        cosmeticManager.currentLoadout
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        // Forward nested ObservableObject changes so SwiftUI views update
        liveActivityManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        storeManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        missionManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        // Buying (or losing) premium changes mission count, the weekly challenge and the phase cap.
        storeManager.$isPremium
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isOnboardingComplete else { return }
                self.missionManager.loadOrGenerateMissions(weeklyAverage: self.weeklySteps / 7)
                self.checkPhaseGraduation()
            }
            .store(in: &cancellables)
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
        cumulativeSteps = progress.totalStepsSinceStart

        let weekData = SharedData.loadWeekData()
        weeklySteps = weekData.reduce(0, +)
        avatarState = SharedData.loadState()
        updateStreakPersistence()

        // Load missions for today
        missionManager.loadOrGenerateMissions(weeklyAverage: weeklySteps / 7)
    }

    func fetchCumulativeSteps(healthManager: HealthKitManager) {
        guard PersistenceManager.shared.userProfile != nil else { return }

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
            currentHour: Calendar.current.component(.hour, from: Date()),
            stepsBeforeNoon: healthManager.stepsBeforeNoon,
            stepsSinceFivePM: healthManager.stepsSinceFivePM
        )
        // Award coins for newly completed missions
        for mission in missionManager.missions where mission.isCompleted && !previouslyCompleted.contains(mission.id) {
            awardCoins(mission.coinReward)
        }

        // Update weekly challenge
        updateWeeklyChallengeProgress(todaySteps: todaySteps)

        // Check for celebrations
        checkCelebrations(todaySteps: todaySteps)

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
        // Don't bail on a completed challenge: a new week must still roll over.
        guard let before = missionManager.weeklyChallenge else { return }
        let alreadyCompletedID = before.isCompleted ? before.id : nil

        let days = HistoryManager.shared.history.days.map {
            WeeklyChallengeProgress.DayTotal(date: $0.date, steps: $0.steps, goalMet: $0.isGoalMet)
        }
        missionManager.updateWeeklyProgress(days: days)

        // Pay once, when this week's challenge completes.
        if let updated = missionManager.weeklyChallenge, updated.isCompleted, updated.id != alreadyCompletedID {
            celebrate(.weeklyChallenge(title: updated.title), coins: updated.coinReward)
        }
    }

    private func updateStreakPersistence() {
        HistoryManager.shared.applyStreakFreezeIfNeeded()
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

        currentPhase = phaseFromWeekly

        PersistenceManager.shared.updateProgress { progress in
            progress.totalStepsSinceStart = self.cumulativeSteps
            progress.currentPhase = phaseFromWeekly
        }

        // Trigger phase evolution celebration
        celebrate(.phaseEvolution(phase: phaseFromWeekly), coins: 250)
        if showCelebration == nil, let event = celebrationManager.dequeueNext() {
            showCelebration = event
        }

        if phaseFromWeekly == 2 && !entitlements.isPremium {
            let progress = PersistenceManager.shared.progressState
            if !progress.hasSeenPaywall {
                requestPaywall()
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

    private func checkCelebrations(todaySteps: Int) {
        let dailyGoal = 7500
        let today = RewardLedger.dayKey()
        var ledger = PersistenceManager.shared.progressState.rewardLedger

        // Daily goal met (once per day, even across relaunches)
        let goalClaimed = ledger.claimDailyGoal(todaySteps: todaySteps, goal: dailyGoal, day: today)

        // Streak milestones (only on the day the goal completes the milestone)
        let streakReward = ledger.claimStreakMilestone(
            streak: currentStreak, todaySteps: todaySteps, goal: dailyGoal, day: today
        )

        if goalClaimed || streakReward != nil {
            let claimed = ledger
            PersistenceManager.shared.updateProgress { $0.rewardLedger = claimed }
        }

        if goalClaimed {
            celebrate(.dailyGoalMet(steps: todaySteps), coins: 25)
            requestReviewIfEligible()
        }

        if let coinReward = streakReward {
            celebrate(.streakMilestone(days: currentStreak), coins: coinReward)

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
            self?.requestPaywall()
        }
    }

    private func updatePersonalRecords(todaySteps: Int) {
        let progress = PersistenceManager.shared.progressState
        var ledger = progress.rewardLedger

        if todaySteps > progress.bestDaySteps {
            let recordClaimed = ledger.claimPersonalRecord(
                todaySteps: todaySteps, previousBest: progress.bestDaySteps, day: RewardLedger.dayKey()
            )
            let claimed = ledger
            PersistenceManager.shared.updateProgress { state in
                state.bestDaySteps = todaySteps
                state.bestDayDate = Date()
                state.rewardLedger = claimed
            }
            if recordClaimed {
                celebrate(.personalRecord(type: "Best Day", value: todaySteps), coins: 150)
            }
        }

        // Cumulative step milestones (each paid once, ever)
        if let milestone = MilestoneCalculator.checkMilestone(
            previousSteps: cumulativeSteps - todaySteps,
            currentSteps: cumulativeSteps
        ), ledger.claimStepMilestone(milestone) {
            let claimed = ledger
            PersistenceManager.shared.updateProgress { $0.rewardLedger = claimed }
            let coinReward = milestone >= 100_000 ? 500 : milestone >= 50_000 ? 300 : 100
            celebrate(.stepMilestone(cumulative: milestone), coins: coinReward)
        }
    }

    // MARK: - Coins

    /// Pays coins and queues the celebration, remembering what was actually paid so the overlay shows it.
    private func celebrate(_ event: CelebrationEvent, coins: Int) {
        celebrationCoins[event.id] = awardCoins(coins)
        celebrationManager.tryTrigger(event)
    }

    /// Coins actually paid for a celebration (premium doubling included).
    func coinsAwarded(for event: CelebrationEvent) -> Int? {
        celebrationCoins[event.id]
    }

    private var celebrationCoins: [String: Int] = [:]

    @discardableResult
    func awardCoins(_ amount: Int) -> Int {
        let finalAmount = storeManager.isPremium ? amount * 2 : amount
        PersistenceManager.shared.updateProgress { state in
            state.stepCoinBalance = RewardLedger.adding(finalAmount, to: state.stepCoinBalance)
        }
        stepCoinToast = finalAmount
        // Cancel the previous timer so an earlier award can't clear a later toast early.
        coinToastTask?.cancel()
        coinToastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.stepCoinToast = nil
        }
        return finalAmount
    }

    private var coinToastTask: Task<Void, Never>?

    // MARK: - Paywall

    /// Never cover a celebration with the paywall sheet; queue it until the overlay closes.
    func requestPaywall() {
        if showCelebration != nil || showShareSheet {
            paywallAfterCelebration = true
        } else {
            showPaywall = true
        }
    }

    /// Called when the celebration overlay is dismissed.
    func celebrationDismissed() {
        // Several celebrations can queue in one update (goal + streak + record); show them in turn.
        if let next = celebrationManager.dequeueNext() {
            showCelebration = next
            return
        }
        showCelebration = nil
        guard paywallAfterCelebration else { return }
        paywallAfterCelebration = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.showPaywall = true
        }
    }
}
