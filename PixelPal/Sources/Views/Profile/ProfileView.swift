import SwiftUI
import StoreKit

/// Stat Grid profile — compact avatar row, 2x2 records grid, Live Activity toggle, premium card.
struct ProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var showManageSubscriptions = false

    private var progress: ProgressState {
        PersistenceManager.shared.progressState
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Space.m) {
                // Compact avatar row
                avatarRow
                    .padding(.top, Space.s)

                // 2x2 stat grid
                statGrid

                // Live Activity toggle card
                liveActivityCard

                // Premium card
                premiumCard

                // Settings link
                settingsLink

                Spacer().frame(height: Space.xl)
            }
            .padding(.horizontal, Space.screen)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
    }

    // MARK: - Avatar Row

    private var avatarRow: some View {
        HStack(spacing: Space.l) {
            AvatarView(
                state: appState.avatarState,
                gender: appState.gender,
                phase: appState.currentPhase,
                size: 52,
                loadout: appState.currentLoadout
            )
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .stroke(Theme.purple.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Phase \(appState.currentPhase)")
                    .font(.ppSection)
                    .foregroundColor(Theme.textPrimary)

                Text(phaseName)
                    .font(.ppCaption)
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: Space.xs) {
                    Image(systemName: "circle.fill")
                        .font(.ppMicro)
                        .foregroundColor(Theme.gold)
                        .accessibilityHidden(true)
                    Text("\(progress.stepCoinBalance)")
                        .font(.ppRowTitle)
                        .foregroundColor(Theme.gold)
                        .monospacedDigit()
                        .numericRoll(value: progress.stepCoinBalance)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(progress.stepCoinBalance) coins")
            }

            Spacer()
        }
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s), GridItem(.flexible(), spacing: Space.s)], spacing: Space.s) {
            statCell(
                value: progress.bestDaySteps > 0 ? progress.bestDaySteps.formatted() : "—",
                label: "Best day"
            )
            statCell(
                value: "\(progress.longestStreak)",
                label: "Longest streak"
            )
            statCell(
                value: formatLargeNumber(progress.totalStepsSinceStart),
                label: "Total steps"
            )
            statCell(
                value: "\(progress.totalActiveDays)",
                label: "Active days"
            )
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: Space.xs) {
            Text(value)
                .font(.ppStat)
                .foregroundColor(Theme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .numericRoll(value: value)

            Text(label)
                .font(.ppMicro)
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .ppCard(padding: Space.l, radius: Radius.button)
        .accessibilityElement(children: .ignore)
        // "—" would be read as "em dash".
        .accessibilityLabel("\(label), \(value == "—" ? "No data yet" : value)")
    }

    // MARK: - Live Activity Card

    private var liveActivityCard: some View {
        let isActive = appState.liveActivityManager.isActive

        return HStack(spacing: Space.m) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.ppStat)
                .foregroundColor(isActive ? Theme.mint : Theme.textTertiary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Live Activity")
                    .font(.ppRowTitle)
                    .foregroundColor(Theme.textPrimary)

                Text(isActive ? "Active on Lock Screen" : "Tap to start")
                    .font(.ppMicro)
                    .foregroundColor(isActive ? Theme.mint : Theme.textTertiary)
            }

            Spacer()

            // Toggle
            Button {
                Haptics.soft()
                toggleLiveActivity()
            } label: {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? Theme.mint : Theme.surfaceStrong)
                    .frame(width: 44, height: 26)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .offset(x: isActive ? 9 : -9)
                    )
                    .motion(Motion.press, value: isActive)
                    .minTapTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Live Activity")
            .accessibilityValue(isActive ? "On" : "Off")
            .accessibilityAddTraits(.isButton)
        }
        .ppCard(padding: 14, radius: Radius.button)
    }

    // MARK: - Premium Card

    private var premiumCard: some View {
        Group {
            if appState.storeManager.isPremium {
                VStack(spacing: 0) {
                    HStack(spacing: Space.m) {
                        Image(systemName: "crown.fill")
                            .font(.ppSection)
                            .foregroundColor(Theme.gold)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: Space.xxs) {
                            Text("Premium active")
                                .font(.ppRowTitle)
                                .foregroundColor(Theme.textPrimary)
                            Text("All features unlocked")
                                .font(.ppMicro)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.mint)
                            .accessibilityHidden(true)
                    }

                    Rectangle()
                        .fill(Theme.stroke)
                        .frame(height: 1)
                        .padding(.vertical, 10)

                    Button {
                        Haptics.soft()
                        showManageSubscriptions = true
                    } label: {
                        HStack(spacing: Space.s) {
                            Image(systemName: "gear")
                                .font(.ppCaption)
                                .foregroundColor(Theme.textTertiary)
                                .accessibilityHidden(true)
                            Text("Manage subscription")
                                .font(.ppCaption)
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.ppMicro)
                                .foregroundColor(Theme.textTertiary)
                                .accessibilityHidden(true)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PPPressableStyle())
                }
                .ppCard(padding: 14, radius: Radius.button)
            } else {
                Button(action: {
                    Haptics.tap()
                    appState.showPaywall = true
                }) {
                    HStack(spacing: Space.m) {
                        Image(systemName: "sparkles")
                            .font(.ppSection)
                            .foregroundColor(Theme.purpleText)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: Space.xxs) {
                            Text("Unlock Premium")
                                .font(.ppRowTitle)
                                .foregroundColor(Theme.textPrimary)
                            Text("All phases, 5 missions, streak freeze")
                                .font(.ppMicro)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.ppCaption.weight(.semibold))
                            .foregroundColor(Theme.purpleText)
                            .accessibilityHidden(true)
                    }
                    .ppCard(padding: 14, radius: Radius.button, tint: Theme.purple)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PPPressableStyle())
            }
        }
    }

    // MARK: - Settings Link

    private var settingsLink: some View {
        Button(action: {
            Haptics.tap()
            appState.showShareSheet = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.ppBody)
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityHidden(true)

                Text("Share Pixel Stepper")
                    .font(.ppRowTitle)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.ppCaption)
                    .foregroundColor(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            .ppCard(padding: 14, radius: Radius.button)
            .contentShape(Rectangle())
        }
        .buttonStyle(PPPressableStyle())
    }

    // MARK: - Helpers

    private func toggleLiveActivity() {
        if appState.liveActivityManager.isActive {
            appState.liveActivityManager.endActivity()
        } else {
            appState.liveActivityManager.startActivity(
                steps: Int(healthManager.currentSteps),
                state: appState.avatarState,
                gender: appState.gender,
                phase: appState.currentPhase
            )
        }
    }

    private var phaseName: String {
        "\(Theme.phaseName(appState.currentPhase)) — \(appState.avatarState.description)"
    }

    /// Locale-aware compact number ("12.3K", "1.2M", or the local equivalent).
    private func formatLargeNumber(_ n: Int) -> String {
        Double(n).formatted(.number.notation(.compactName).precision(.fractionLength(0...1)))
    }
}
