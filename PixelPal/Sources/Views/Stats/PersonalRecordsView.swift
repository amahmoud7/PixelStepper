import SwiftUI

/// Grid of personal bests: best day, longest streak, total steps, goal days.
struct PersonalRecordsView: View {
    /// Observed so the records re-render when progress is saved (a computed read alone wouldn't).
    @ObservedObject private var persistence = PersistenceManager.shared

    private var progress: ProgressState {
        persistence.progressState
    }

    var body: some View {
        VStack(spacing: Space.m) {
            HStack {
                Text("Personal records")
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Space.m),
                GridItem(.flexible(), spacing: Space.m)
            ], spacing: Space.m) {
                recordCard(
                    icon: "trophy.fill",
                    color: Theme.gold,
                    value: progress.bestDaySteps > 0 ? "\(progress.bestDaySteps.formatted())" : "—",
                    label: "Best day",
                    subtitle: bestDaySubtitle
                )

                recordCard(
                    icon: "flame.fill",
                    color: Theme.amber,
                    value: "\(progress.longestStreak)",
                    label: "Longest streak",
                    subtitle: streakSubtitle
                )

                recordCard(
                    icon: "figure.walk",
                    color: Theme.mint,
                    value: formatLargeNumber(progress.totalStepsSinceStart),
                    label: "Total steps",
                    subtitle: "All time"
                )

                recordCard(
                    icon: "calendar",
                    color: Theme.blue,
                    value: "\(progress.totalActiveDays)",
                    label: "Goal days",
                    subtitle: "All time"
                )
            }
        }
        .glassCard()
    }

    private var streakSubtitle: String {
        switch progress.longestStreak {
        case 0: return "Start walking!"
        case 1: return "day in a row"
        default: return "days in a row"
        }
    }

    private var bestDaySubtitle: String {
        guard let date = progress.bestDayDate else { return "No data yet" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    /// Locale-aware compact number ("12.3K", "1.2M", or the local equivalent).
    private func formatLargeNumber(_ number: Int) -> String {
        Double(number).formatted(.number.notation(.compactName).precision(.fractionLength(0...1)))
    }

    @ViewBuilder
    private func recordCard(icon: String, color: Color, value: String, label: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.ppStat)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.ppStat)
                .foregroundColor(Theme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .numericRoll(value: value)

            Text(label)
                .font(.ppCaption.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.ppMicro)
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .ppCard(padding: Space.m, radius: Radius.row)
        .accessibilityElement(children: .ignore)
        // "—" would be read as "em dash".
        .accessibilityLabel("\(label), \(value == "—" ? "No data yet" : value), \(subtitle)")
    }
}
