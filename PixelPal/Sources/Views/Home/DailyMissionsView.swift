import SwiftUI

/// Daily missions list with left-border color coding and strikethrough completed; one Premium footer for free users.
struct DailyMissionsView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var lastCompleted: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            // Coins are hidden until the shop ships; balances still accrue.
            SectionHeader("Daily missions")

            // Mission rows
            ForEach(appState.missionManager.missions) { mission in
                MissionRow(mission: mission)
            }

            // Weekly challenge (premium only)
            if let challenge = appState.missionManager.weeklyChallenge {
                WeeklyChallengeRow(challenge: challenge)
            }

            // Free users: one quiet upsell instead of several locked cards
            if !appState.storeManager.isPremium {
                premiumFooter
            }
        }
        .onAppear {
            lastCompleted = appState.missionManager.completedCount
        }
        // One reward tap per newly completed mission; nothing on appear.
        .onChange(of: appState.missionManager.completedCount) { count in
            if let last = lastCompleted, count > last {
                Haptics.reward()
            }
            lastCompleted = count
        }
    }

    private func showPaywall() {
        Haptics.tap()
        appState.showPaywall = true
    }

    // MARK: - Premium Footer

    private var premiumFooter: some View {
        Button(action: showPaywall) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.body)
                    .foregroundColor(Theme.purpleText)
                    .accessibilityHidden(true)

                Text("2 more missions + weekly challenge with Premium")
                    .font(.ppRowTitle)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: Space.s)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.purpleText)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Space.m)
            .ppCard(padding: 0, radius: Radius.row, tint: Theme.purple)
            .contentShape(Rectangle())
        }
        .buttonStyle(PPPressableStyle())
        .accessibilityHint("Opens Premium")
    }
}

// MARK: - Section Header

/// Home section title: sentence case, sits outside cards, optional trailing accessory.
private struct SectionHeader<Accessory: View>: View {
    let title: String
    let accessory: Accessory

    init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .center, spacing: Space.s) {
            Text(title)
                .font(.ppSection)
                .foregroundColor(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: Space.s)

            accessory
        }
    }
}

extension SectionHeader where Accessory == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

// MARK: - Mission Row

private struct MissionRow: View {
    let mission: DailyMission

    /// Mission accent; streak missions use amber rather than red (no-shame palette).
    private var color: Color {
        mission.type == .streakExtend ? Theme.amber : Color(hex: mission.type.color)
    }

    private var accessibilityText: String {
        if mission.isCompleted {
            return mission.title
        }
        return "\(mission.title), \(mission.progress.formatted()) of \(mission.target.formatted())"
    }

    /// Checkbox grows with the row's text (capped) so it never looks tiny beside large labels.
    @ScaledMetric(relativeTo: .footnote) private var scaledIcon: CGFloat = 22
    private var iconSize: CGFloat { min(scaledIcon, 36) }

    var body: some View {
        HStack(spacing: 0) {
            // Left color border
            Rectangle()
                .fill(mission.isCompleted ? Theme.mint : color)
                .frame(width: 3)

            HStack(spacing: 10) {
                statusIcon
                    .frame(width: iconSize, height: iconSize)

                // Content
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(mission.title)
                        .font(.ppRowTitle)
                        .foregroundColor(mission.isCompleted ? Theme.textTertiary : Theme.textPrimary)
                        .strikethrough(mission.isCompleted, color: Theme.textTertiary)

                    if !mission.isCompleted {
                        Text("\(mission.progress.formatted()) / \(mission.target.formatted())")
                            .font(.ppMicro)
                            .foregroundColor(Theme.textTertiary)
                            .numericRoll(value: mission.progress)
                    }
                }

                Spacer()
            }
            .padding(.leading, 13)
            .padding(.trailing, 14)
            .padding(.vertical, mission.isCompleted ? 12 : 10)
        }
        .background(
            mission.isCompleted
                ? Theme.mint.opacity(0.06)
                : Color.white.opacity(mission.progress > 0 ? 0.03 : 0.02)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        .overlay {
            // Progress bar for in-progress missions
            if !mission.isCompleted && mission.progress > 0 {
                GeometryReader { geo in
                    VStack {
                        Spacer()
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 4)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [color, color.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, geo.size.width - (iconSize + 13)) * mission.progressFraction)
                                    .shadow(color: color.opacity(0.4), radius: 3)
                            }
                            .padding(.leading, iconSize + 13)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .motion(Motion.snappy, value: mission.isCompleted)
        .motion(Motion.number, value: mission.progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityValue(mission.isCompleted ? "Completed" : "")
    }

    @ViewBuilder
    private var statusIcon: some View {
        if mission.isCompleted {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.mint)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: iconSize * 0.5, weight: .bold))
                        .foregroundColor(.white)
                )
                .transition(.scale(scale: 0.5).combined(with: .opacity))
        } else if mission.progress > 0 {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(color, lineWidth: 1.5)
                )
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: iconSize * 0.42))
                        .foregroundColor(color)
                )
                .transition(.opacity)
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                )
                .transition(.opacity)
        }
    }
}

// MARK: - Weekly Challenge Row

private struct WeeklyChallengeRow: View {
    let challenge: WeeklyChallenge

    private var daysLeftText: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Sunday=1, Saturday=7. Days until Sunday (end of week)
        let daysLeft = weekday == 1 ? 0 : (8 - weekday)
        return daysLeft == 0 ? "Ends today" : "\(daysLeft)d left"
    }

    @ScaledMetric(relativeTo: .footnote) private var scaledIcon: CGFloat = 28
    private var iconSize: CGFloat { min(scaledIcon, 44) }

    private var accessibilityText: String {
        var parts = ["Weekly challenge", challenge.title, challenge.description]
        if !challenge.isCompleted {
            parts.append("\(challenge.progress.formatted()) of \(challenge.target.formatted())")
        }
        parts.append(daysLeftText)
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.caption2)
                    .foregroundColor(Theme.gold)
                Text("WEEKLY CHALLENGE")
                    .font(.ppOverline)
                    .tracking(1)
                    .foregroundColor(Theme.gold)
                Spacer()
                Text(daysLeftText)
                    .font(.ppMicro)
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            HStack(spacing: 10) {
                // Icon (scales with text, capped)
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(Theme.gold.opacity(challenge.isCompleted ? 0.2 : 0.1))
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        ZStack {
                            if challenge.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: iconSize * 0.43, weight: .bold))
                                    .foregroundColor(Theme.mint)
                                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                            } else {
                                Image(systemName: challenge.type.icon)
                                    .font(.system(size: iconSize * 0.43, weight: .bold))
                                    .foregroundColor(Theme.gold)
                                    .transition(.opacity)
                            }
                        }
                    )

                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(challenge.title)
                        .font(.ppRowTitle)
                        .foregroundColor(challenge.isCompleted ? Theme.textTertiary : Theme.textPrimary)
                        .strikethrough(challenge.isCompleted, color: Theme.textTertiary)

                    Text(challenge.description)
                        .font(.ppMicro)
                        .foregroundColor(Theme.textTertiary)

                    if !challenge.isCompleted {
                        Text("\(challenge.progress.formatted()) / \(challenge.target.formatted())")
                            .font(.ppMicro)
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .ppCard(padding: 0, radius: Radius.row, tint: Theme.gold)
        .overlay {
            if !challenge.isCompleted && challenge.progress > 0 {
                GeometryReader { geo in
                    VStack {
                        Spacer()
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 3)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(Theme.gold)
                                    .frame(width: max(0, geo.size.width - 28) * challenge.progressFraction)
                                    .shadow(color: Theme.gold.opacity(0.4), radius: 3)
                            }
                            .padding(.horizontal, 14)
                    }
                    .padding(.bottom, 2)
                }
                .accessibilityHidden(true)
            }
        }
        .motion(Motion.snappy, value: challenge.isCompleted)
        .motion(Motion.number, value: challenge.progress)
        .onChange(of: challenge.isCompleted) { done in
            if done { Haptics.reward() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityValue(challenge.isCompleted ? "Completed" : "")
    }
}
