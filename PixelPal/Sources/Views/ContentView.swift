import SwiftUI
import StoreKit

/// Root view: splash → onboarding or main tab view.
struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var appState = AppStateManager()
    /// Observed so finishing onboarding switches to the tabs (and reloads state) immediately.
    @ObservedObject private var persistence = PersistenceManager.shared
    @State private var showSplash = !LaunchFlags.uiTest

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            if showSplash {
                SplashScreenView {
                    withMotion(Motion.smooth) {
                        showSplash = false
                    }
                }
            } else if !isOnboardingComplete {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .transition(.opacity)
            }
        }
        .motion(Motion.smooth, value: isOnboardingComplete)
        .onAppear {
            prepareForUITestsIfNeeded()
            appState.loadSavedData()
            // Ask for Health access only after onboarding has explained why (idempotent once answered).
            // Today's/weekly fetch happens in the authorization callback;
            // cumulative fetch follows via onChange(isAuthorized).
            if isOnboardingComplete && !LaunchFlags.uiTest {
                healthManager.requestAuthorization { _ in }
            }
            Task {
                // Local entitlements first (offline-safe), then products from the App Store.
                await appState.storeManager.updatePurchasedProducts()
                await appState.storeManager.setup()
            }
        }
        .onChange(of: isOnboardingComplete) { completed in
            guard completed else { return }
            // Pick up the chosen character and generate today's missions without a relaunch.
            appState.loadSavedData()
            if !LaunchFlags.uiTest {
                healthManager.requestAuthorization { _ in }
            }
        }
        .onChange(of: healthManager.currentSteps) { _ in
            appState.updateState(healthManager: healthManager)
        }
        .onChange(of: healthManager.cumulativeSteps) { _ in
            appState.cumulativeSteps = healthManager.cumulativeSteps
        }
        .onChange(of: healthManager.isAuthorized) { authorized in
            if authorized {
                appState.fetchCumulativeSteps(healthManager: healthManager)
            }
        }
        .onChange(of: healthManager.dailyStepsLast7Days) { dailyMap in
            appState.backfillWeeklyHistory(from: dailyMap, healthManager: healthManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            NotificationManager.shared.scheduleReEngagement()
            appState.liveActivityManager.markIdle()
            // Finish pending writes before the app can be suspended.
            PersistenceManager.shared.flush()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            NotificationManager.shared.cancelReEngagement()
            NotificationManager.shared.refreshSchedule()
            // Refresh health data so SharedData + widget stay in sync
            healthManager.fetchData()
            appState.fetchCumulativeSteps(healthManager: healthManager)
            // Catch subscription lapses/refunds that don't emit a transaction.
            Task { await appState.storeManager.updatePurchasedProducts() }
        }
        .preferredColorScheme(.dark)
    }

    private var isOnboardingComplete: Bool {
        persistence.userProfile != nil
    }

    /// Screenshot tests: start clean or pre-onboarded. No-op for normal launches.
    private func prepareForUITestsIfNeeded() {
        guard LaunchFlags.uiTest else { return }
        if LaunchFlags.resetData {
            persistence.clearAll()
        }
        if LaunchFlags.skipOnboarding && persistence.userProfile == nil {
            persistence.saveUserProfile(UserProfile.createNew(gender: .female))
        }
        if LaunchFlags.demoData {
            seedDemoData()
        }
    }

    /// History and progress for App Store screenshots: a 12-day streak, Phase 2, nothing to celebrate.
    private func seedDemoData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var history = DailyHistory.createNew()
        let past = LaunchFlags.Demo.pastDays
        for (index, steps) in past.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: index - past.count, to: today) else { continue }
            history.recordDay(DailyGoalState.create(for: date, steps: steps, goal: 7500))
        }
        history.recordDay(DailyGoalState.create(for: today, steps: LaunchFlags.Demo.todaySteps, goal: 7500))
        HistoryManager.shared.history = history
        persistence.saveDailyHistory(history)

        persistence.updateProgress { progress in
            progress.currentPhase = 2
            progress.totalStepsSinceStart = LaunchFlags.Demo.cumulativeSteps
            progress.todaySteps = LaunchFlags.Demo.todaySteps
            progress.currentStreak = LaunchFlags.Demo.streakDays
            progress.longestStreak = 21
            progress.bestDaySteps = 14_382
            progress.totalActiveDays = 48
            progress.hasSeenPaywall = true
            progress.hasRequestedReview = true
        }
        UserDefaults.standard.set(true, forKey: "liveActivityCardDismissed")
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.ppCard()
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

// MARK: - Phase Display View

struct PhaseDisplayView: View {
    let phase: Int
    let isPremium: Bool

    private var phaseColor: Color { Theme.phaseColor(phase) }
    private var phaseIcon: String { Theme.phaseIcon(phase) }
    private var phaseName: String { Theme.phaseName(phase) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: phaseIcon)
                .font(.title3)
                .foregroundColor(phaseColor)
                .accessibilityHidden(true)

            // One line always; shrink rather than wrap ("Pha/se 2") or push the bar off-screen.
            Text("Phase \(phase)")
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .layoutPriority(1)

            Text("\u{2022} \(phaseName)")
                .font(.subheadline)
                .foregroundColor(phaseColor)
                .lineLimit(1)

            if isPremium {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(Theme.gold)
                    .accessibilityLabel("Premium")
            }
        }
        .minimumScaleFactor(0.7)
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.s)
        .background(phaseColor.opacity(0.2), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
