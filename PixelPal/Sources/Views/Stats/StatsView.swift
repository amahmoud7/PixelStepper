import SwiftUI

/// Stats tab: Week memory + personal records + phase progress + 30-day calendar heatmap.
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
                    // Week memory
                    WeekMemorySection()
                        .padding(.horizontal, Space.screen)
                } else {
                    StatsEmptyState()
                        .padding(.horizontal, Space.screen)
                }

                // Personal records
                PersonalRecordsView()
                    .padding(.horizontal, Space.screen)

                // Phase progress
                PhaseProgressCard(
                    weeklySteps: appState.weeklySteps,
                    currentPhase: appState.currentPhase,
                    isPremium: appState.storeManager.isPremium
                )
                .padding(.horizontal, Space.screen)

                // 30-day calendar heatmap
                if hasHistory {
                    MonthCalendarView()
                        .padding(.horizontal, Space.screen)
                }

                Spacer().frame(height: Space.xl)
            }
            .padding(.top, Space.s)
        }
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

    var body: some View {
        VStack(spacing: Space.m) {
            HStack {
                Text("Phase progress")
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("Phase \(currentPhase) · \(phaseName)")
                    .font(.ppCaption.weight(.semibold))
                    .foregroundColor(progressTextColor)
            }

            if currentPhase < 4 {
                // Step count display
                HStack(alignment: .firstTextBaseline, spacing: Space.xxs) {
                    Text(weeklySteps.formatted())
                        .font(.ppStat)
                        .foregroundColor(Theme.textPrimary)
                        .monospacedDigit()
                        .numericRoll(value: weeklySteps)
                    Text("/ \(nextThreshold.formatted()) steps")
                        .font(.ppBody)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.ppBody.weight(.bold))
                        .foregroundColor(progressTextColor)
                        .monospacedDigit()
                        .numericRoll(value: progress)
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
                    Text("Unlock Premium for Phase \(currentPhase + 1)")
                        .font(.ppMicro)
                        .foregroundColor(Theme.purpleText)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
