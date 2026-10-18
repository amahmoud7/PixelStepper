import SwiftUI

/// Daily missions list with left-border color coding, strikethrough completed, premium missions visible.
struct DailyMissionsView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var lastCompleted: Int?

    private var coinBalance: Int {
        PersistenceManager.shared.progressState.stepCoinBalance
    }

    private var allMissionsCompleted: Bool {
        appState.missionManager.completedCount == appState.missionManager.missions.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Daily Missions + coin balance
            HStack {
                Text("Daily Missions")
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                HStack(spacing: Space.xs) {
                    CoinIcon()
                    Text("\(coinBalance)")
                        .font(.ppRowTitle)
                        .foregroundColor(Theme.gold)
                        .numericRoll(value: coinBalance)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .ppCard(padding: 0, radius: Radius.chip, tint: Theme.gold)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(coinBalance) coins")
            }

            // Mission rows
            ForEach(appState.missionManager.missions) { mission in
                MissionRow(mission: mission)
            }

            // Weekly challenge (premium only) or locked placeholder
            if let challenge = appState.missionManager.weeklyChallenge {
                WeeklyChallengeRow(challenge: challenge)
            } else if !appState.storeManager.isPremium {
                lockedWeeklyChallengeRow
            }

            // Premium missions or post-completion upsell
            if !appState.storeManager.isPremium {
                if allMissionsCompleted {
                    postCompletionBanner
                } else {
                    premiumMissionsSection
                }
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

    // MARK: - Premium Missions

    private var premiumMissionsSection: some View {
        Button(action: showPaywall) {
            VStack(alignment: .leading, spacing: Space.s) {
                // Dashed divider
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .foregroundColor(Theme.purple.opacity(0.2))
                    .frame(height: 1)

                Text("PREMIUM MISSIONS")
                    .font(.ppOverline)
                    .tracking(1)
                    .foregroundColor(Theme.purpleText)

                // Locked mission rows
                lockedMissionRow(title: "Evening Push — 2,000 steps after 5pm")
                lockedMissionRow(title: "Stay Active — 500+ steps/hr for 4 hrs")
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PPPressableStyle())
        .accessibilityLabel("Premium missions: Evening Push, Stay Active")
        .accessibilityHint("Opens Premium")
    }

    // MARK: - Locked Weekly Challenge

    private var lockedWeeklyChallengeRow: some View {
        Button(action: showPaywall) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.gold.opacity(0.5))
                    Text("WEEKLY CHALLENGE")
                        .font(.ppOverline)
                        .tracking(1)
                        .foregroundColor(Theme.gold)
                }

                Spacer()

                HStack(spacing: Space.xs) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.gold.opacity(0.5))
                    Text("Unlock with Premium")
                        .font(.ppMicro)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Space.m)
            .ppCard(padding: 0, radius: Radius.row, tint: Theme.gold)
            .contentShape(Rectangle())
        }
        .buttonStyle(PPPressableStyle())
        .accessibilityLabel("Weekly challenge, unlock with Premium")
    }

    // MARK: - Post-Completion Banner

    private var postCompletionBanner: some View {
        Button(action: showPaywall) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.body)
                    .foregroundColor(Theme.purple)
                    .accessibilityHidden(true)

                Text("Unlock 2 bonus missions")
                    .font(.ppRowTitle)
                    .foregroundColor(Theme.textSecondary)

                Spacer()

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
    }

    private func lockedMissionRow(title: String) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Theme.purple.opacity(0.15))
                .frame(width: 3)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.purple.opacity(0.1))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.purple.opacity(0.5))
                    )

                Text(title)
                    .font(.ppCaption)
                    .foregroundColor(Theme.textTertiary)

                Spacer()
            }
            .padding(.leading, 13)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
    }
}

// MARK: - Coin Icon

/// The one coin glyph used across Home.
private struct CoinIcon: View {
    var body: some View {
        Image(systemName: "circle.fill")
            .font(.caption2)
            .foregroundStyle(Theme.gold)
            .accessibilityHidden(true)
    }
}

// MARK: - Mission Row

private struct MissionRow: View {
    let mission: DailyMission

    private var color: Color { Color(hex: mission.type.color) }

    private var accessibilityText: String {
        if mission.isCompleted {
            return "\(mission.title), \(mission.coinReward) coins"
        }
        return "\(mission.title), \(mission.progress.formatted()) of \(mission.target.formatted()), \(mission.coinReward) coins"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left color border
            Rectangle()
                .fill(mission.isCompleted ? Theme.mint : color)
                .frame(width: 3)

            HStack(spacing: 10) {
                statusIcon
                    .frame(width: 22, height: 22)

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

                // Coin reward
                HStack(spacing: 3) {
                    Text(mission.isCompleted ? "+\(mission.coinReward)" : "\(mission.coinReward)")
                        .font(.ppMicro.weight(.bold))
                        .foregroundColor(Theme.gold)
                    CoinIcon()
                        .opacity(mission.isCompleted ? 1 : 0.6)
                }
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
                                    .frame(width: max(0, geo.size.width - 35) * mission.progressFraction)
                                    .shadow(color: color.opacity(0.4), radius: 3)
                            }
                            .padding(.leading, 35)
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
                        .font(.system(size: 11, weight: .bold))
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
                        .font(.system(size: 9))
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

    private var accessibilityText: String {
        var parts = ["Weekly challenge", challenge.title, challenge.description]
        if !challenge.isCompleted {
            parts.append("\(challenge.progress.formatted()) of \(challenge.target.formatted())")
        }
        parts.append("\(challenge.coinReward) coins")
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
                // Icon
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(Theme.gold.opacity(challenge.isCompleted ? 0.2 : 0.1))
                    .frame(width: 28, height: 28)
                    .overlay(
                        ZStack {
                            if challenge.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.mint)
                                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                            } else {
                                Image(systemName: challenge.type.icon)
                                    .font(.system(size: 12, weight: .bold))
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

                HStack(spacing: 3) {
                    Text("\(challenge.coinReward)")
                        .font(.ppCaption.weight(.bold))
                        .foregroundColor(Theme.gold)
                    CoinIcon()
                }
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
