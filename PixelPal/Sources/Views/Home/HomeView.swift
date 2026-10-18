import SwiftUI

/// Home tab: Avatar + streak hero + daily missions + step count.
struct HomeView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var todaySteps: Int { Int(healthManager.currentSteps) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Top bar
                topBar
                    .padding(.top, Space.s)

                // HealthKit unavailable banner (iPad/no Health app)
                if !healthManager.isHealthDataAvailable {
                    healthKitUnavailableBanner
                        .padding(.horizontal, Space.screen)
                }

                // "Not seeing steps?" help (shows when authorized but 0 steps for a while)
                if healthManager.isAuthorized && healthManager.currentSteps == 0 && hasProfile {
                    stepsHelpBanner
                        .padding(.horizontal, Space.screen)
                }

                // Hero avatar
                AvatarView(
                    state: appState.avatarState,
                    gender: appState.gender,
                    phase: appState.currentPhase,
                    loadout: appState.currentLoadout,
                    animatesEntrance: true
                )

                // Step count display
                VStack(spacing: Space.xxs) {
                    Text(todaySteps.formatted())
                        .font(.ppLargeTitle)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .numericRoll(value: todaySteps)
                    Text("steps today")
                        .font(.ppRowTitle)
                        .foregroundColor(Theme.textTertiary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(todaySteps.formatted()) steps today")

                // Streak hero (Glass Dashboard)
                StreakHeroView(
                    streak: appState.currentStreak,
                    todaySteps: todaySteps,
                    dailyGoal: 7500,
                    missionsCompleted: appState.missionManager.completedCount,
                    missionsTotal: appState.missionManager.missions.count,
                    isPremium: appState.storeManager.isPremium,
                    onUpgradeTap: { appState.showPaywall = true }
                )
                .padding(.horizontal, Space.screen)

                // Daily missions
                DailyMissionsView()
                    .padding(.horizontal, Space.screen)

                if let lastUpdate = SharedData.loadLastUpdateDate() {
                    Text("Updated \(lastUpdate.formatted(date: .omitted, time: .shortened))")
                        .font(.ppMicro)
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer().frame(height: Space.xl)
            }
        }
        .refreshable {
            healthManager.invalidateCache()
            await healthManager.refreshToday()
            appState.fetchCumulativeSteps(healthManager: healthManager)
            appState.updateState(healthManager: healthManager)
        }
    }

    // MARK: - HealthKit Banners

    @State private var showStepsHelp = false
    @State private var dismissedStepsHelp = false

    private var hasProfile: Bool {
        PersistenceManager.shared.userProfile != nil
    }

    /// Shows when HealthKit is not available on the device (iPad, etc.)
    private var healthKitUnavailableBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.slash.fill")
                .font(.title3)
                .foregroundColor(.red.opacity(0.8))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Health data not available")
                    .font(.ppRowTitle)
                    .foregroundColor(Theme.textPrimary)
                Text("This device doesn't support step tracking")
                    .font(.ppMicro)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .ppCard(padding: Space.m, radius: Radius.row, tint: .red)
        .accessibilityElement(children: .combine)
    }

    /// Shows when authorized but steps are 0 — user may have denied read access in Health settings.
    private var stepsHelpBanner: some View {
        Group {
            if !dismissedStepsHelp {
                HStack(spacing: 0) {
                    Button {
                        Haptics.tap()
                        showStepsHelp = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: Space.xxs) {
                                Text("Not seeing your steps?")
                                    .font(.ppRowTitle)
                                    .foregroundColor(Theme.textPrimary)
                                Text("Tap for help enabling step access")
                                    .font(.ppMicro)
                                    .foregroundColor(Theme.textTertiary)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.leading, Space.m)
                        .padding(.vertical, Space.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PPPressableStyle())

                    Button {
                        Haptics.soft()
                        withMotion(Motion.snappy, reduceMotion: reduceMotion) { dismissedStepsHelp = true }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.textTertiary)
                            .minTapTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                    .padding(.trailing, Space.xs)
                }
                .ppCard(padding: 0, radius: Radius.row, tint: .orange)
                .transition(.opacity)
                .alert("Enable Step Tracking", isPresented: $showStepsHelp) {
                    Button("Open Health App") {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Dismiss", role: .cancel) {
                        dismissedStepsHelp = true
                    }
                } message: {
                    Text("To enable step tracking:\n\n1. Open the Health app\n2. Tap your profile icon (top right)\n3. Tap \"Apps\" under Privacy\n4. Tap \"Pixel Stepper\"\n5. Turn on \"Steps\"")
                }
            }
        }
    }

    // MARK: - Top Bar

    private var isReadyToEvolve: Bool {
        guard !appState.storeManager.isPremium else { return false }
        guard appState.currentPhase >= 2 else { return false }
        return appState.weeklySteps >= PhaseCalculator.phase2Max
    }

    private func showPaywall() {
        Haptics.tap()
        appState.showPaywall = true
    }

    private var topBar: some View {
        HStack {
            PhaseDisplayView(phase: appState.currentPhase, isPremium: appState.storeManager.isPremium)

            if isReadyToEvolve {
                Button(action: showPaywall) {
                    Text("Ready to evolve")
                        .font(.ppMicro.weight(.bold))
                        .foregroundColor(Theme.purpleText)
                        .padding(.horizontal, Space.s)
                        .padding(.vertical, Space.xs)
                        .background(
                            Capsule()
                                .fill(Theme.purple.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Theme.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .minTapTarget()
                }
                .buttonStyle(PPPressableStyle())
                .accessibilityHint("Opens Premium")
            }

            Spacer()

            if !appState.storeManager.isPremium {
                Button(action: showPaywall) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(Theme.gold)
                        .padding(Space.s)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                        .minTapTarget()
                }
                .buttonStyle(PPPressableStyle())
                .accessibilityLabel("Premium")
            }

            Button {
                Haptics.tap()
                appState.showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.medium))
                    .foregroundColor(Theme.textSecondary)
                    .padding(Space.s)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .minTapTarget()
            }
            .buttonStyle(PPPressableStyle())
            .accessibilityLabel("Share")
        }
        .padding(.horizontal, Space.screen)
    }

}
