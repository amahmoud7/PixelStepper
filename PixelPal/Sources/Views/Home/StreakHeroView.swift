import SwiftUI

/// Glass Dashboard streak display — ring + stats side-by-side, steps/missions grid below, keep-going nudge.
struct StreakHeroView: View {
    let streak: Int
    let todaySteps: Int
    let dailyGoal: Int
    let missionsCompleted: Int
    let missionsTotal: Int
    var isPremium: Bool = false
    var onUpgradeTap: (() -> Void)?

    private var progress: Double {
        min(Double(todaySteps) / Double(dailyGoal), 1.0)
    }

    private var showsNudge: Bool {
        streak > 0 && todaySteps < dailyGoal
    }

    private var streakColor: Color {
        if streak == 0 { return Theme.textTertiary }
        if streak >= 30 { return Theme.gold }
        if streak >= 7 { return Color(red: 1.0, green: 0.2, blue: 0.1) }
        return Theme.amber
    }

    private var bestStreak: Int {
        PersistenceManager.shared.progressState.longestStreak
    }

    var body: some View {
        VStack(spacing: 10) {
            if streak == 0 {
                zeroStreakView
            } else {
                activeStreakView
            }
        }
    }

    // MARK: - Zero Streak

    private var zeroStreakView: some View {
        HStack(spacing: Space.l) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Theme.surface, lineWidth: 5)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .motion(Motion.number, value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .numericRoll(value: Int(progress * 100))
                    .frame(width: 56)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(Int(progress * 100)) percent of daily goal")

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("START YOUR STREAK")
                    .font(.ppOverline)
                    .tracking(1)
                    .foregroundColor(Theme.textTertiary)

                Text("0 days")
                    .font(.ppStat)
                    .foregroundColor(Theme.textPrimary)

                Text("\(max(0, dailyGoal - todaySteps).formatted()) steps to begin")
                    .font(.ppMicro)
                    .foregroundColor(Theme.blue)
            }

            Spacer(minLength: 0)
        }
        .ppCard(radius: Radius.card)
    }

    // MARK: - Active Streak (Glass Dashboard)

    private var activeStreakView: some View {
        VStack(spacing: 10) {
            // Main glass card: ring + stats side-by-side
            HStack(spacing: Space.l) {
                // Streak ring
                ZStack {
                    Circle()
                        .stroke(Theme.surface, lineWidth: 5)
                        .frame(width: 76, height: 76)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [streakColor, streakColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: streakColor.opacity(0.3), radius: 6)
                        .motion(Motion.number, value: progress)

                    VStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(streakColor)

                        Text("\(streak)")
                            .font(.ppStat)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .numericRoll(value: streak)
                    }
                    .frame(width: 60)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(streak) day streak")

                // Stats column
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("CURRENT STREAK")
                        .font(.ppOverline)
                        .tracking(1)
                        .foregroundColor(Theme.textTertiary)

                    Text("^[\(streak) day](inflect: true)")
                        .font(.ppStat)
                        .foregroundColor(Theme.textPrimary)

                    // 7-day dots
                    weekDots

                    Text("Best: ^[\(bestStreak) day](inflect: true)")
                        .font(.ppMicro)
                        .foregroundColor(streakColor)
                }

                Spacer(minLength: 0)
            }
            .ppCard(radius: Radius.card)

            // 2-column grid: steps + missions
            HStack(spacing: 10) {
                // Steps mini card
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("TODAY")
                        .font(.ppOverline)
                        .tracking(1)
                        .foregroundColor(Theme.textTertiary)

                    Text(todaySteps.formatted())
                        .font(.ppStat)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .numericRoll(value: todaySteps)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.surface)
                                .frame(height: 3)
                            Capsule()
                                .fill(Theme.mint)
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .motion(Motion.number, value: progress)
                    .accessibilityHidden(true)

                    Text("\(Int(progress * 100))% of goal")
                        .font(.ppMicro)
                        .foregroundColor(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ppCard(padding: 14, radius: Radius.button)

                // Missions mini card
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("MISSIONS")
                        .font(.ppOverline)
                        .tracking(1)
                        .foregroundColor(Theme.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(missionsCompleted)")
                            .font(.ppStat)
                            .foregroundColor(Theme.textPrimary)
                            .numericRoll(value: missionsCompleted)
                        Text("/\(missionsTotal)")
                            .font(.ppBody)
                            .foregroundColor(Theme.textTertiary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(missionsCompleted) of \(missionsTotal) missions done")

                    HStack(spacing: Space.xs) {
                        ForEach(0..<missionsTotal, id: \.self) { i in
                            Capsule()
                                .fill(i < missionsCompleted
                                    ? Theme.mint
                                    : (i == missionsCompleted
                                        ? Theme.purple.opacity(0.4)
                                        : Theme.surface))
                                .frame(height: 3)
                        }
                    }
                    .accessibilityHidden(true)

                    let balance = PersistenceManager.shared.progressState.stepCoinBalance
                    HStack(spacing: Space.xs) {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.gold)
                            .accessibilityHidden(true)
                        Text("\(balance) coins")
                            .font(.ppMicro)
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ppCard(padding: 14, radius: Radius.button)
            }

            // Gentle nudge when today's goal isn't met yet
            if showsNudge {
                StreakAtRiskView(
                    stepsRemaining: dailyGoal - todaySteps,
                    streak: streak,
                    isPremium: isPremium,
                    onUpgradeTap: onUpgradeTap
                )
            }
        }
    }

    // MARK: - Week Dots

    private var weekDots: some View {
        let weekData = HistoryManager.shared.history.weekViewData()
        let metCount = weekData.filter { $0.isGoalMet }.count

        return HStack(spacing: Space.xs) {
            ForEach(weekData) { day in
                Circle()
                    .fill(day.isToday && !day.isGoalMet
                        ? Theme.amber.opacity(0.4)
                        : (day.isGoalMet ? Theme.mint : Color.white.opacity(0.1)))
                    .frame(width: 6, height: 6)
                    .overlay(
                        day.isToday && !day.isGoalMet
                            ? Circle().stroke(Theme.amber.opacity(0.6), lineWidth: 1)
                            : nil
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metCount) of 7 days at goal")
    }
}

/// Encouraging "keep going" banner with a walk-time estimate. No pressure, no warning icons.
struct StreakAtRiskView: View {
    let stepsRemaining: Int
    let streak: Int
    var isPremium: Bool = false
    var onUpgradeTap: (() -> Void)?

    /// ~100 steps per minute of walking, rounded up.
    private var walkMinutes: Int {
        max(1, (stepsRemaining + 99) / 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.body)
                    .foregroundColor(Theme.amber)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("Keep your streak going")
                        .font(.ppRowTitle)
                        .foregroundColor(Theme.amber)

                    Text("\(stepsRemaining.formatted()) steps · about \(walkMinutes) min walk")
                        .font(.ppMicro)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .accessibilityElement(children: .combine)

            if !isPremium, let onUpgradeTap {
                Button {
                    Haptics.tap()
                    onUpgradeTap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.caption2)
                            .foregroundColor(Theme.cyan)
                            .accessibilityHidden(true)
                        Text("Premium includes Streak Freeze")
                            .font(.ppMicro)
                            .foregroundColor(Theme.textSecondary)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.textTertiary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.04))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PPPressableStyle())
            }
        }
        .ppCard(padding: 0, radius: Radius.row, tint: Theme.amber)
        .clipShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
    }
}
