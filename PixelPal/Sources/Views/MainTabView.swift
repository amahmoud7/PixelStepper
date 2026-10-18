import SwiftUI

/// Native 3-tab layout: Home, Stats, Profile.
/// System TabView gives Liquid Glass on iOS 26, standard materials before that, and VoiceOver for free.
struct MainTabView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var selectedTab: AppTab = .home

    /// Not `Tab`: that name collides with SwiftUI.Tab on iOS 18+.
    enum AppTab: Hashable {
        case home, stats, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabScreenBackground()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            NavigationStack {
                StatsView()
                    .tabScreenBackground()
                    .navigationTitle("Stats")
            }
            .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            .tag(AppTab.stats)

            NavigationStack {
                ProfileView()
                    .tabScreenBackground()
                    .navigationTitle("Profile")
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(AppTab.profile)
        }
        .tint(Theme.purple)
        .overlay { overlays }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView(storeManager: appState.storeManager, gender: appState.gender, currentPhase: appState.currentPhase)
        }
        .sheet(isPresented: $appState.showShareSheet) {
            ShareSheetView(data: appState.shareCardData)
        }
        .onChange(of: appState.stepCoinToast) { coins in
            guard let coins else { return }
            UIAccessibility.post(notification: .announcement, argument: "Plus \(coins) coins")
        }
    }

    // MARK: - Overlays

    private var overlays: some View {
        ZStack {
            // Celebration overlay (highest priority)
            if let event = appState.showCelebration {
                CelebrationOverlay(event: event, coins: appState.coinsAwarded(for: event)) {
                    appState.celebrationDismissed()
                } onShare: {
                    appState.paywallAfterCelebration = false
                    appState.showCelebration = nil
                    appState.showShareSheet = true
                }
                .accessibilityAddTraits(.isModal)
                .transition(.opacity)
            }

            // Step Moment overlay (only when no celebration showing)
            if appState.showStepMoment && appState.showCelebration == nil {
                StepMomentView()
                    .transition(.opacity)
            }
        }
        .motion(Motion.smooth, value: appState.showCelebration != nil)
    }
}

private extension View {
    /// Each tab paints the app gradient behind its content (TabView/NavigationStack are opaque otherwise).
    func tabScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .overlay(alignment: .bottom) { CoinToastOverlay() }
    }
}

/// "+N coins" toast. Lives inside each tab so it sits above the system tab bar at any height.
private struct CoinToastOverlay: View {
    @EnvironmentObject var appState: AppStateManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // The celebration overlay already shows coins, so skip the toast under it.
            if let coins = appState.stepCoinToast, appState.showCelebration == nil {
                HStack(spacing: Space.s) {
                    Image(systemName: "circle.fill")
                        .font(.ppCaption)
                        .foregroundStyle(Theme.gold)
                        .accessibilityHidden(true)
                    Text("+\(coins) coins")
                        .font(.ppBody.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .numericRoll(value: coins)
                }
                .padding(.horizontal, Space.xl)
                .padding(.vertical, Space.m)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
                .padding(.bottom, Space.m)
                .transition(.motionSlide(.bottom, reduceMotion: reduceMotion))
            }
        }
        .allowsHitTesting(false)
        .motion(Motion.snappy, value: appState.stepCoinToast)
    }
}
