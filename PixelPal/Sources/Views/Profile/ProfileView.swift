import SwiftUI

/// Stat Grid profile — compact avatar row, 2x2 records grid, Live Activity toggle, premium card.
struct ProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var healthManager: HealthKitManager

    private var progress: ProgressState {
        PersistenceManager.shared.progressState
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                // Compact avatar row
                avatarRow
                    .padding(.top, 16)

                // 2x2 stat grid
                statGrid

                // Live Activity toggle card
                liveActivityCard

                // Premium card
                premiumCard

                // Settings link
                settingsLink

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Avatar Row

    private var avatarRow: some View {
        HStack(spacing: 16) {
            AvatarView(
                state: appState.avatarState,
                gender: appState.gender,
                phase: appState.currentPhase,
                loadout: appState.currentLoadout
            )
            .scaleEffect(0.5)
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.49, green: 0.36, blue: 0.99).opacity(0.3), lineWidth: 1.5)
                    )
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Phase \(appState.currentPhase)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(phaseName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("\(progress.stepCoinBalance)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                }
            }

            Spacer()
        }
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            statCell(
                value: progress.bestDaySteps > 0 ? progress.bestDaySteps.formatted() : "—",
                label: "Best Day"
            )
            statCell(
                value: "\(progress.longestStreak)",
                label: "Best Streak"
            )
            statCell(
                value: formatLargeNumber(progress.totalStepsSinceStart),
                label: "Total Steps"
            )
            statCell(
                value: "\(progress.totalActiveDays)",
                label: "Active Days"
            )
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Live Activity Card

    private var liveActivityCard: some View {
        HStack(spacing: 12) {
            Image(systemName: appState.liveActivityManager.isActive ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right")
                .font(.system(size: 20))
                .foregroundColor(appState.liveActivityManager.isActive ? Color(red: 0.2, green: 0.78, blue: 0.35) : .white.opacity(0.4))

            VStack(alignment: .leading, spacing: 2) {
                Text("Live Activity")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text(appState.liveActivityManager.isActive ? "Active on Lock Screen" : "Tap to start")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(appState.liveActivityManager.isActive ? Color(red: 0.2, green: 0.78, blue: 0.35) : .white.opacity(0.3))
            }

            Spacer()

            // Toggle
            Button(action: toggleLiveActivity) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(appState.liveActivityManager.isActive ? Color(red: 0.2, green: 0.78, blue: 0.35) : Color.white.opacity(0.1))
                    .frame(width: 44, height: 26)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .offset(x: appState.liveActivityManager.isActive ? 9 : -9)
                            .animation(.easeInOut(duration: 0.15), value: appState.liveActivityManager.isActive)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Premium Card

    private var premiumCard: some View {
        Group {
            if appState.storeManager.isPremium {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Premium Active")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("All features unlocked")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.2, green: 0.78, blue: 0.35))
                    }

                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.vertical, 10)

                    Button(action: openSubscriptionManagement) {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                            Text("Manage Subscription")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            } else {
                Button(action: { appState.showPaywall = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.49, green: 0.36, blue: 0.99))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Premium")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("All phases, 5 missions, streak freeze")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.49, green: 0.36, blue: 0.99))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.49, green: 0.36, blue: 0.99).opacity(0.08),
                                        Color(red: 0.0, green: 0.83, blue: 1.0).opacity(0.04)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.49, green: 0.36, blue: 0.99).opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    // MARK: - Settings Link

    private var settingsLink: some View {
        Button(action: { appState.showShareSheet = true }) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))

                Text("Share Pixel Stepper")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Helpers

    private func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }

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
        switch appState.currentPhase {
        case 1: return "Seedling — \(appState.avatarState.description)"
        case 2: return "Growing — \(appState.avatarState.description)"
        case 3: return "Thriving — \(appState.avatarState.description)"
        case 4: return "Legendary — \(appState.avatarState.description)"
        default: return appState.avatarState.description
        }
    }

    private func formatLargeNumber(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        } else if n >= 1_000 {
            return String(format: "%.0fK", Double(n) / 1_000)
        }
        return "\(n)"
    }
}
