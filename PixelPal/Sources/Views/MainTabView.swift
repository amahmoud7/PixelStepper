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
    }

    // MARK: - Overlays

    private var overlays: some View {
        ZStack {
            // Celebration overlay (highest priority)
            if let event = appState.showCelebration {
                CelebrationOverlay(event: event, coins: appState.coinsAwarded(for: event), gender: appState.gender) {
                    appState.celebrationDismissed()
                } onShare: {
                    appState.paywallAfterCelebration = false
                    appState.showCelebration = nil
                    appState.showShareSheet = true
                }
                .accessibilityAddTraits(.isModal)
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
    }
}
