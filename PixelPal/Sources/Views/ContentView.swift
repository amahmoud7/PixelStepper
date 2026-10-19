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

            Text("Phase \(phase)")
                .font(.headline)
                .foregroundColor(.white)

            Text("\u{2022} \(phaseName)")
                .font(.subheadline)
                .foregroundColor(phaseColor)

            if isPremium {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(Theme.gold)
                    .accessibilityLabel("Premium")
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.s)
        .background(phaseColor.opacity(0.2), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
