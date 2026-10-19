import SwiftUI
import Charts

/// Stats tab: this week's chart → phase progress → 30-day calendar → personal records.
struct StatsView: View {
    @EnvironmentObject var appState: AppStateManager
    @ObservedObject private var historyManager = HistoryManager.shared

    /// True until the first day with recorded steps lands in history.
    private var hasHistory: Bool {
        historyManager.history.days.contains { $0.steps > 0 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Space.screen) {
                if hasHistory {
                    // This week (bar chart replaces the old 7-dot memory row)
                    ThisWeekCard(days: historyManager.last7Days())
                        .padding(.horizontal, Space.screen)
                } else {
                    StatsEmptyState()
                        .padding(.horizontal, Space.screen)
                }

                // Phase progress
                PhaseProgressCard(
                    weeklySteps: appState.weeklySteps,
                    currentPhase: appState.currentPhase,
                    isPremium: appState.storeManager.isPremium,
                    onUnlock: { appState.showPaywall = true }
                )
                .padding(.horizontal, Space.screen)

                // 30-day calendar heatmap
                if hasHistory {
                    MonthCalendarView()
                        .padding(.horizontal, Space.screen)
                }

                // Personal records
                PersonalRecordsView()
                    .padding(.horizontal, Space.screen)

                Spacer().frame(height: Space.xl)
            }
            .padding(.top, Space.s)
        }
    }
}

// MARK: - This Week

private struct ThisWeekCard: View {
    let days: [DailyHistory.DayViewData]

    private let goal = 7500

    private var daysAtGoal: Int { days.filter(\.isGoalMet).count }
    private var totalSteps: Int { days.reduce(0) { $0 + $1.steps } }

    /// Keeps the goal line visible on low-step weeks.
    private var yMax: Int { max(days.map(\.steps).max() ?? 0, goal) * 11 / 10 }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("This week")
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("\(daysAtGoal) of 7 days at goal · \(totalSteps.formatted()) steps")
                    .font(.ppCaption)
                    .foregroundColor(Theme.textSecondary)
            }

            Chart {
                ForEach(days) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", day.steps)
                    )
                    .foregroundStyle(barColor(for: day))
                    .cornerRadius(2)
                    .accessibilityLabel(Text(day.isToday ? "Today" : day.date.formatted(.dateTime.weekday(.wide))))
                    .accessibilityValue(Text("\(day.steps.formatted()) steps\(day.isGoalMet ? ", goal met" : "")"))
                }

                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Theme.textTertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    // Leading, so it never collides with the trailing y-axis labels.
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal")
                            .font(.ppMicro)
                            .foregroundColor(Theme.textTertiary)
                    }
                    .accessibilityLabel(Text("Daily goal"))
                    .accessibilityValue(Text("\(goal.formatted()) steps"))
            }
            .chartYScale(domain: 0...yMax)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .frame(height: 160)
            // Axis labels are chart chrome; cap them so bars keep their room at accessibility sizes.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        .glassCard()
    }

    private func barColor(for day: DailyHistory.DayViewData) -> Color {
        if day.isGoalMet { return Theme.goalMet }
        if day.isToday { return Theme.today }
        return Theme.belowGoal
    }
}

// MARK: - Empty State

private struct StatsEmptyState: View {
    var body: some View {
        VStack(spacing: Space.s) {
            Image(systemName: "figure.walk")
                .font(.ppTitle)
                .foregroundColor(Theme.purpleText)
                .accessibilityHidden(true)

            Text("Your first week will show up here as you walk.")
                .font(.ppBody)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.s)
        .ppCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Phase Progress Card

private struct PhaseProgressCard: View {
    let weeklySteps: Int
    let currentPhase: Int
    let isPremium: Bool
    let onUnlock: () -> Void

    private var nextThreshold: Int {
        PhaseCalculator.nextThreshold(for: currentPhase)
    }

    private var progress: Double {
        min(max(PhaseCalculator.weeklyProgress(weeklySteps: weeklySteps, currentPhase: currentPhase), 0), 1)
    }

    private var progressColor: Color {
        Theme.phaseColor(currentPhase)
    }

    /// Phase color for small text; the brand purple is too dark at caption sizes.
    private var progressTextColor: Color {
        currentPhase == 3 ? Theme.purpleText : progressColor
    }

    private var phaseName: String {
        Theme.phaseName(currentPhase)
    }

    private var nextPhaseName: String {
        Theme.phaseName(currentPhase + 1)
    }

    private var phaseTitle: some View {
        Text("Phase progress")
            .font(.ppSection)
            .foregroundColor(Theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var stepCount: some View {
        Text(weeklySteps.formatted())
            .font(.ppStat)
            .foregroundColor(Theme.textPrimary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .layoutPriority(1)
            .numericRoll(value: weeklySteps)
    }

    private var percentText: some View {
        Text("\(Int(progress * 100))%")
            .font(.ppBody.weight(.bold))
            .foregroundColor(progressTextColor)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .numericRoll(value: progress)
    }

    private var phaseLabel: some View {
        Text("Phase \(currentPhase) · \(phaseName)")
            .font(.ppCaption.weight(.semibold))
            .foregroundColor(progressTextColor)
    }

    var body: some View {
        VStack(spacing: Space.m) {
            // Side by side when it fits; stacked at large text sizes.
            ViewThatFits(in: .horizontal) {
                HStack {
                    phaseTitle
                    Spacer()
                    phaseLabel
                }
                VStack(alignment: .leading, spacing: Space.xs) {
                    phaseTitle
                    phaseLabel
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if currentPhase < 4 {
                // Step count display
                // One row when it fits; otherwise the count and "of N steps" stack instead of
                // the target wrapping word by word under the number.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: Space.xxs) {
                        stepCount
                        Text("/ \(nextThreshold.formatted()) steps")
                            .font(.ppBody)
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                            .fixedSize()
                        Spacer(minLength: Space.s)
                        percentText
                    }
                    VStack(alignment: .leading, spacing: Space.xxs) {
                        HStack(alignment: .firstTextBaseline) {
                            stepCount
                            Spacer(minLength: Space.s)
                            percentText
                        }
                        Text("of \(nextThreshold.formatted()) steps")
                            .font(.ppBody)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(weeklySteps.formatted()) of \(nextThreshold.formatted()) steps this week")
                .accessibilityValue("\(Int(progress * 100)) percent")

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.surfaceStrong)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [progressColor, progressColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .shadow(color: progressColor.opacity(0.3), radius: 4)
                            .motion(Motion.number, value: progress)
                    }
                }
                .frame(height: 8)
                .accessibilityHidden(true)

                if currentPhase >= 2 && !isPremium {
                    Button {
                        Haptics.tap()
                        onUnlock()
                    } label: {
                        HStack(spacing: Space.xs) {
                            Text("Unlock Premium for Phase \(currentPhase + 1)")
                            Image(systemName: "chevron.right")
                                .accessibilityHidden(true)
                        }
                        .font(.ppCaption.weight(.semibold))
                        .foregroundColor(Theme.purpleText)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PPPressableStyle())
                } else {
                    let remaining = max(0, nextThreshold - weeklySteps)
                    Text("\(remaining.formatted()) steps to \(nextPhaseName) · resets weekly")
                        .font(.ppMicro)
                        .foregroundColor(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Space.xxs) {
                    Text(weeklySteps.formatted())
                        .font(.ppStat)
                        .foregroundColor(Theme.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .layoutPriority(1)
                        .numericRoll(value: weeklySteps)
                    Text("steps this week")
                        .font(.ppBody)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .accessibilityElement(children: .combine)

                RoundedRectangle(cornerRadius: 4)
                    .fill(progressColor)
                    .frame(height: 8)
                    .shadow(color: progressColor.opacity(0.3), radius: 4)
                    .accessibilityHidden(true)

                Text("Maximum evolution reached!")
                    .font(.ppMicro)
                    .foregroundColor(Theme.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .glassCard()
    }
}
