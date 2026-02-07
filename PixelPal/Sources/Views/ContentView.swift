import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var liveActivityManager = LiveActivityManager()
    @StateObject private var storeManager = StoreManager.shared

    @State private var avatarState: AvatarState = .low
    @State private var gender: Gender = .male
    @State private var showPaywall: Bool = false

    // Phase tracking
    @State private var currentPhase: Int = 1
    @State private var cumulativeSteps: Int = 0
    @State private var weeklySteps: Int = 0
    @State private var previousPhase: Int = 1

    private var isOnboardingComplete: Bool {
        let profile = PersistenceManager.shared.userProfile
        return profile != nil && healthManager.isAuthorized
    }

    var body: some View {
        ZStack {
            // Ambient gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.1, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.1, blue: 0.12)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if !isOnboardingComplete {
                OnboardingView()
            } else {
                mainContentView
            }
        }
        .onAppear {
            loadSavedData()
            if healthManager.isAuthorized {
                healthManager.fetchData()
                fetchCumulativeSteps()
            }
            // Defer StoreKit product loading to after launch
            Task {
                await storeManager.setup()
            }
        }
        .onChange(of: healthManager.currentSteps) { _ in
            updateState()
        }
        .onChange(of: healthManager.cumulativeSteps) { _ in
            checkPhaseGraduation()
        }
        .onChange(of: healthManager.isAuthorized) { authorized in
            if authorized {
                loadSavedData()
                healthManager.fetchData()
                fetchCumulativeSteps()
            }
        }
        .onChange(of: healthManager.dailyStepsLast7Days) { dailyMap in
            backfillWeeklyHistory(from: dailyMap)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: storeManager, gender: gender)
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top bar: Phase name + Crown button
                topBar
                    .padding(.top, 8)

                // Hero avatar
                AvatarView(
                    state: avatarState,
                    gender: gender,
                    phase: currentPhase
                )

                // Stats glass card
                statsCard

                // Week memory
                WeekMemorySection()
                    .padding(.horizontal, 20)

                // Phase progress (weekly steps toward next phase)
                PhaseProgressView(
                    weeklySteps: weeklySteps,
                    currentPhase: currentPhase,
                    isPremium: storeManager.isPremium
                )
                .glassCard()
                .padding(.horizontal, 20)

                // Live Activity controls
                liveActivityCard

                if let lastUpdate = SharedData.loadLastUpdateDate() {
                    Text("Updated \(lastUpdate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }

                Spacer().frame(height: 20)
            }
        }
        .refreshable {
            healthManager.fetchData()
            fetchCumulativeSteps()
            updateState()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            PhaseDisplayView(phase: currentPhase, isPremium: storeManager.isPremium)

            Spacer()

            // Crown button for non-premium users (paywall re-entry)
            if !storeManager.isPremium {
                Button(action: { showPaywall = true }) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.yellow.opacity(0.8))
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 10) {
            Text("\(Int(healthManager.currentSteps))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()

            Text("steps today")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(avatarState.description)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(phaseColor.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(phaseColor.opacity(0.15))
                .clipShape(Capsule())

            Text("\(weeklySteps.formatted()) steps this week")
                .font(.caption)
                .foregroundColor(phaseColor.opacity(0.7))
        }
        .glassCard()
        .padding(.horizontal, 20)
    }

    // MARK: - Live Activity Card

    private var liveActivityCard: some View {
        VStack(spacing: 12) {
            if liveActivityManager.isActive {
                Button(action: {
                    liveActivityManager.endActivity()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Pixel Pace")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(16)
                }

                Text("Live Activity is running")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.8))
            } else {
                Button(action: {
                    liveActivityManager.startActivity(
                        steps: Int(healthManager.currentSteps),
                        state: avatarState,
                        gender: gender,
                        phase: currentPhase
                    )
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Pixel Pace")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.white, Color(white: 0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .white.opacity(0.15), radius: 8, y: 2)
                }

                Text("Start Pixel Pace then swipe up to view the Dynamic Island")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .glassCard()
        .padding(.horizontal, 20)
    }

    // MARK: - Phase Color

    private var phaseColor: Color {
        switch currentPhase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    // MARK: - State Management

    private func loadSavedData() {
        if let profile = PersistenceManager.shared.userProfile {
            gender = profile.selectedGender
        } else if let savedGender = SharedData.loadGender() {
            gender = savedGender
        }

        let progress = PersistenceManager.shared.progressState
        currentPhase = progress.currentPhase
        previousPhase = progress.currentPhase
        cumulativeSteps = progress.totalStepsSinceStart

        // Compute weekly total from saved week data
        let weekData = SharedData.loadWeekData()
        weeklySteps = weekData.reduce(0, +)

        avatarState = SharedData.loadState()
    }

    private func fetchCumulativeSteps() {
        guard let profile = PersistenceManager.shared.userProfile else { return }

        Task {
            await healthManager.fetchCumulativeStepsAsync(since: profile.createdAt)
            await MainActor.run {
                cumulativeSteps = healthManager.cumulativeSteps
                checkPhaseGraduation()
            }
        }
    }

    /// Check if weekly steps qualify for phase graduation.
    private func checkPhaseGraduation() {
        let entitlements = PersistenceManager.shared.entitlements
        let phaseFromWeekly = PhaseCalculator.currentPhase(
            totalSteps: weeklySteps,
            isPremium: entitlements.isPremium
        )

        // Only advance, never demote
        if phaseFromWeekly > currentPhase {
            currentPhase = phaseFromWeekly

            PersistenceManager.shared.updateProgress { progress in
                progress.totalStepsSinceStart = cumulativeSteps
                progress.currentPhase = phaseFromWeekly
            }

            if phaseFromWeekly == 2 && !entitlements.isPremium {
                let progress = PersistenceManager.shared.progressState
                if !progress.hasSeenPaywall {
                    showPaywall = true
                    PersistenceManager.shared.updateProgress { progress in
                        progress.hasSeenPaywall = true
                    }
                }
            }
        }
    }

    /// Backfills HistoryManager with per-day HealthKit data for the last 7 days,
    /// then recalculates weeklySteps and checks phase graduation.
    private func backfillWeeklyHistory(from dailyMap: [Date: Int]) {
        guard !dailyMap.isEmpty else { return }

        let historyManager = HistoryManager.shared
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        for dayOffset in (-6)...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            let dayStart = calendar.startOfDay(for: date)

            if let steps = dailyMap[dayStart], steps > 0 {
                if dayOffset < 0 {
                    // Backfill past days with real HealthKit data
                    historyManager.recordDay(date: dayStart, steps: steps)
                } else {
                    // For today: only update if HealthKit has more steps than current live value
                    let currentTodaySteps = Int(healthManager.currentSteps)
                    if steps > currentTodaySteps {
                        historyManager.updateToday(steps: steps)
                    }
                }
            }
        }

        // Recalculate weekly total from backfilled history
        let weekDays = historyManager.last7Days()
        let weekStepArray = weekDays.map { $0.steps }
        SharedData.saveWeekData(weekStepArray)
        weeklySteps = weekStepArray.reduce(0, +)

        checkPhaseGraduation()
    }

    private func updateState() {
        let newState = AvatarLogic.determineState(steps: healthManager.currentSteps)
        self.avatarState = newState

        SharedData.saveState(state: newState, steps: healthManager.currentSteps, phase: currentPhase)
        SharedData.saveCumulativeSteps(cumulativeSteps)

        // Save week data for widgets
        let historyManager = HistoryManager.shared
        historyManager.updateToday(steps: Int(healthManager.currentSteps))
        let weekDays = historyManager.last7Days()
        let weekStepArray = weekDays.map { $0.steps }
        SharedData.saveWeekData(weekStepArray)

        // Update weekly total and check for phase graduation
        weeklySteps = weekStepArray.reduce(0, +)
        checkPhaseGraduation()

        PersistenceManager.shared.updateProgress { progress in
            progress.todaySteps = Int(healthManager.currentSteps)
            progress.totalStepsSinceStart = cumulativeSteps
        }

        if liveActivityManager.isActive {
            liveActivityManager.updateActivity(
                steps: Int(healthManager.currentSteps),
                state: newState,
                gender: gender,
                phase: currentPhase,
                cumulativeSteps: cumulativeSteps
            )
        }
    }
}

// MARK: - Glass Card Modifier

private struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

// MARK: - Phase Display View

private struct PhaseDisplayView: View {
    let phase: Int
    let isPremium: Bool

    private var phaseColor: Color {
        switch phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    private var phaseIcon: String {
        switch phase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    private var phaseName: String {
        switch phase {
        case 1: return "Seedling"
        case 2: return "Growing"
        case 3: return "Thriving"
        case 4: return "Legendary"
        default: return "Unknown"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: phaseIcon)
                .font(.title3)
                .foregroundColor(phaseColor)

            Text("Phase \(phase)")
                .font(.headline)
                .foregroundColor(.white)

            Text("• \(phaseName)")
                .font(.subheadline)
                .foregroundColor(phaseColor)

            if isPremium {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(phaseColor.opacity(0.2))
        .cornerRadius(20)
    }
}

// MARK: - Phase Progress View

private struct PhaseProgressView: View {
    let weeklySteps: Int
    let currentPhase: Int
    let isPremium: Bool

    private var nextThreshold: Int {
        PhaseCalculator.nextThreshold(for: currentPhase)
    }

    private var progress: Double {
        PhaseCalculator.weeklyProgress(weeklySteps: weeklySteps, currentPhase: currentPhase)
    }

    private var stepsToNext: Int {
        PhaseCalculator.stepsToNextPhase(weeklySteps: weeklySteps, currentPhase: currentPhase) ?? 0
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            if currentPhase < 4 {
                if currentPhase >= 2 && !isPremium {
                    Text("Unlock Premium for Phase \(currentPhase + 1)")
                        .font(.caption2)
                        .foregroundColor(.purple.opacity(0.8))
                } else {
                    Text("\(weeklySteps.formatted()) / \(nextThreshold.formatted()) this week")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.8))
                }
            } else {
                Text("Maximum evolution reached!")
                    .font(.caption2)
                    .foregroundColor(.orange.opacity(0.8))
            }
        }
    }

    private var progressColor: Color {
        switch currentPhase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }
}
