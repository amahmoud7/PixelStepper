import ActivityKit
import SwiftUI

/// Home tab: character inside a goal ring (the one focal point), streak row, Lock Screen card, daily missions.
struct HomeView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("liveActivityCardDismissed") private var liveActivityCardDismissed = false

    private var todaySteps: Int { Int(healthManager.currentSteps) }

    // Mirrors AvatarLogic.determineState thresholds (low < 2,500 ≤ neutral < 7,500 ≤ vital).
    private let neutralThreshold = 2500
    private let dailyGoal = 7500

    var body: some View {
        ScrollView(showsIndicators: false) {
            // 24pt between sections; 12pt within a section.
            VStack(spacing: Space.xl) {
                // Top bar
                topBar
                    .padding(.top, Space.s)

                // HealthKit unavailable banner (iPad/no Health app)
                if !healthManager.isHealthDataAvailable {
                    healthKitUnavailableBanner
                        .padding(.horizontal, Space.screen)
                }

                // "Not seeing steps?" help: still 0 steps late enough in the day that it's probably access, not sleep
                if healthManager.isAuthorized && healthManager.currentSteps == 0 && hasProfile && isLateEnoughForStepsHelp {
                    stepsHelpBanner
                        .padding(.horizontal, Space.screen)
                }

                // Hero: character inside the goal ring, steps, energy
                hero

                // Streak row
                StreakHeroView(streak: appState.currentStreak)
                    .padding(.horizontal, Space.screen)

                // One-time Lock Screen invitation
                if showsLiveActivityCard {
                    liveActivityCard
                        .padding(.horizontal, Space.screen)
                        .transition(.opacity)
                }

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

    /// 0 steps before 11:00 is usually just an early morning.
    private var isLateEnoughForStepsHelp: Bool {
        Calendar.current.component(.hour, from: Date()) >= 11
    }

    // MARK: - Live Activity Card

    private var showsLiveActivityCard: Bool {
        appState.isOnboardingComplete
            && !appState.liveActivityManager.isActive
            && !liveActivityCardDismissed
            && ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private var liveActivityCard: some View {
        HStack(spacing: Space.m) {
            Image(systemName: "lock.iphone")
                .font(.title3)
                .foregroundColor(Theme.purpleText)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Show on Lock Screen")
                    .font(.ppRowTitle)
                    .foregroundColor(Theme.textPrimary)
                Text("Your character and steps at a glance")
                    .font(.ppMicro)
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: Space.xs)

            Button(action: startLiveActivity) {
                Text("Start")
                    .font(.ppRowTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.purple))
                    .minTapTarget()
            }
            .buttonStyle(PPPressableStyle())
            .accessibilityLabel("Start Live Activity")

            Button {
                Haptics.soft()
                withMotion(Motion.snappy, reduceMotion: reduceMotion) {
                    liveActivityCardDismissed = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.textTertiary)
                    .minTapTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.leading, Space.m)
        .padding(.trailing, Space.xs)
        .ppCard(padding: 0, radius: Radius.row, tint: Theme.purple)
    }

    private func startLiveActivity() {
        // Starting flips isActive (synchronously), which hides this card.
        withMotion(Motion.snappy, reduceMotion: reduceMotion) {
            appState.liveActivityManager.startActivity(
                steps: todaySteps,
                state: appState.avatarState,
                gender: appState.gender,
                phase: appState.currentPhase
            )
        }
        if appState.liveActivityManager.isActive {
            Haptics.success()
        } else {
            Haptics.warning()
        }
    }

    // MARK: - Hero

    private var goalProgress: Double {
        min(1, Double(todaySteps) / Double(dailyGoal))
    }

    private var ringColor: Color {
        todaySteps >= dailyGoal ? Theme.goalMet : Theme.phaseColor(appState.currentPhase)
    }

    private var energyState: AvatarState {
        AvatarLogic.determineState(steps: todaySteps)
    }

    private var energyCaption: String {
        switch energyState {
        case .low:
            return "Low energy · \(max(0, neutralThreshold - todaySteps).formatted()) steps to neutral"
        case .neutral:
            return "Neutral · \(max(0, dailyGoal - todaySteps).formatted()) steps to vital"
        case .vital:
            return "Vital · goal reached"
        }
    }

    private var heroAccessibilityLabel: String {
        let energy: String
        switch energyState {
        case .low: energy = "low energy"
        case .neutral: energy = "neutral energy"
        case .vital: energy = "vital energy"
        }
        return "Your character, \(Theme.phaseName(appState.currentPhase)) phase, "
            + "\(todaySteps.formatted()) of \(dailyGoal.formatted()) steps, \(energy)"
    }

    /// Sized so ring + count + caption fit above the tab bar on iPhone SE.
    private var hero: some View {
        VStack(spacing: Space.m) {
            ZStack {
                Circle()
                    .stroke(Theme.surfaceStrong, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: goalProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .motion(Motion.number, value: goalProgress)

                AvatarView(
                    state: appState.avatarState,
                    gender: appState.gender,
                    phase: appState.currentPhase,
                    size: 170,
                    loadout: appState.currentLoadout,
                    animatesEntrance: true
                )
            }
            .frame(width: 240, height: 240)

            VStack(spacing: 0) {
                Text(todaySteps.formatted())
                    .font(.ppLargeTitle)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .numericRoll(value: todaySteps)
                Text("of \(dailyGoal.formatted()) steps")
                    .font(.ppBody)
                    .foregroundColor(Theme.textSecondary)
            }

            Text(energyCaption)
                .font(.ppCaption)
                .foregroundColor(Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Space.screen)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroAccessibilityLabel)
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
