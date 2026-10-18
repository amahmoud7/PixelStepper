import SwiftUI

/// Spotlight Stage celebration — dark stage, golden spotlight, sparkles, "Milestone Unlocked" badge, gold CTA.
struct CelebrationOverlay: View {
    let event: CelebrationEvent
    /// Coins actually awarded for this event; the pill is hidden when nil or 0.
    var coins: Int? = nil
    let onDismiss: () -> Void
    let onShare: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var titleFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 44
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 40
    @State private var isShowing = false
    @State private var iconIn = false
    @State private var isDismissing = false
    @State private var spotlightScale: CGFloat = 0.3
    @State private var appearTask: Task<Void, Never>?
    @State private var autoDismissTask: Task<Void, Never>?
    @State private var dismissTask: Task<Void, Never>?

    private var accentColor: Color {
        switch event {
        case .streakMilestone: return Theme.amber
        case .phaseEvolution: return Theme.purple
        case .dailyGoalMet: return Theme.mint
        case .personalRecord: return Theme.gold
        case .stepMilestone: return Theme.blue
        case .weeklyChallenge: return Theme.gold
        }
    }

    private var awardedCoins: Int? {
        guard let coins, coins > 0 else { return nil }
        return coins
    }

    var body: some View {
        ZStack {
            // Pure black background
            Color(red: 0.02, green: 0.02, blue: 0.03)
                .ignoresSafeArea()
                .opacity(isShowing ? 1 : 0)
                .onTapGesture { dismiss() }
                .accessibilityHidden(true)

            // Spotlight glow layers
            Group {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(y: -60)
                    .scaleEffect(reduceMotion ? 1 : spotlightScale)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.gold.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .offset(y: -60)
                    .scaleEffect(reduceMotion ? 1 : spotlightScale)
            }
            .opacity(isShowing ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // Sparkle particles (skipped under Reduce Motion)
            if !reduceMotion {
                SparkleParticleView(accentColor: accentColor)
                    .ignoresSafeArea()
                    .opacity(isShowing ? 1 : 0)
            }

            // Content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // "Milestone Unlocked" badge
                Text("MILESTONE UNLOCKED")
                    .font(.ppOverline)
                    .tracking(1)
                    .foregroundColor(Theme.gold)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                            .fill(Theme.gold.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                                    .stroke(Theme.gold.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .opacity(isShowing ? 1 : 0)
                    .offset(y: isShowing || reduceMotion ? 0 : 10)

                Spacer()
                    .frame(height: Space.xl)

                // Achievement icon
                achievementIcon
                    .scaleEffect(iconIn || reduceMotion ? 1.0 : 0.5)
                    .opacity(iconIn ? 1.0 : 0)
                    .accessibilityHidden(true)

                Spacer()
                    .frame(height: Space.xl)

                // Category label
                Text(eventCategory)
                    .font(.ppBody)
                    .foregroundColor(Theme.textTertiary)
                    .tracking(3)
                    .textCase(.uppercase)
                    .opacity(isShowing ? 1 : 0)

                // Title
                Text(event.title)
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, Space.xl)
                    .opacity(isShowing ? 1 : 0)
                    .offset(y: isShowing || reduceMotion ? 0 : 15)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)

                Spacer()
                    .frame(height: Space.m)

                // Subtitle
                Text(event.subtitle)
                    .font(.ppBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(3)
                    .opacity(isShowing ? 1 : 0)

                // Coin reward pill (only when coins were actually awarded)
                if let awardedCoins {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.gold)
                            .accessibilityHidden(true)
                        Text("+\(awardedCoins) coins earned")
                            .font(.ppRowTitle)
                            .foregroundColor(Theme.gold)
                    }
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Theme.gold.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Theme.gold.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .padding(.top, 20)
                    .opacity(isShowing ? 1 : 0)
                }

                Spacer()

                // Share CTA — gold gradient
                Button {
                    Haptics.tap()
                    dismiss(then: onShare)
                } label: {
                    Text("Share Achievement")
                }
                .buttonStyle(PPPrimaryButtonStyle(colors: [Theme.gold, Theme.amber], foreground: .black))
                .padding(.horizontal, 40)
                .opacity(isShowing ? 1 : 0)

                // Dismiss hint
                Button {
                    Haptics.soft()
                    dismiss()
                } label: {
                    Text("Tap to dismiss")
                        .font(.ppCaption)
                        .foregroundColor(Theme.textTertiary)
                        .padding(.horizontal, Space.l)
                        .minTapTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
                .padding(.top, Space.s)
                .padding(.bottom, 36)
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            Haptics.prepare()

            withMotion(Motion.smooth, reduceMotion: reduceMotion) {
                isShowing = true
            }
            withMotion(Motion.bouncy.delay(0.12), reduceMotion: reduceMotion) {
                iconIn = true
            }
            withMotion(Motion.reveal, reduceMotion: reduceMotion) {
                spotlightScale = 1.0
            }

            appearTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { return }
                if case .phaseEvolution = event {
                    Haptics.celebrate()
                } else {
                    Haptics.success()
                }
                titleFocused = true
            }

            // VoiceOver users need time to read the overlay; let them dismiss it themselves.
            guard !UIAccessibility.isVoiceOverRunning else { return }
            autoDismissTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                dismiss()
            }
        }
        .onDisappear {
            appearTask?.cancel()
            autoDismissTask?.cancel()
            dismissTask?.cancel()
        }
    }

    /// Animates out once, then runs `action` (or `onDismiss`). Repeat calls are ignored.
    private func dismiss(then action: (() -> Void)? = nil) {
        guard !isDismissing else { return }
        isDismissing = true
        appearTask?.cancel()
        autoDismissTask?.cancel()
        withMotion(Motion.exit, reduceMotion: reduceMotion) {
            isShowing = false
            iconIn = false
            spotlightScale = 0.3
        }
        let completion = action ?? onDismiss
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            completion()
        }
    }

    // MARK: - Achievement Icon

    @ViewBuilder
    private var achievementIcon: some View {
        let iconConfig: (name: String, color: Color) = {
            switch event {
            case .streakMilestone: return ("flame.fill", Theme.amber)
            case .phaseEvolution: return ("sparkles", Theme.purple)
            case .dailyGoalMet: return ("checkmark.circle.fill", Theme.mint)
            case .personalRecord: return ("trophy.fill", Theme.gold)
            case .stepMilestone: return ("figure.walk", Theme.blue)
            case .weeklyChallenge: return ("trophy.fill", Theme.gold)
            }
        }()

        ZStack {
            Circle()
                .fill(iconConfig.color.opacity(0.1))
                .frame(width: 96, height: 96)

            Circle()
                .stroke(iconConfig.color.opacity(0.3), lineWidth: 2)
                .frame(width: 96, height: 96)

            // Scales with Dynamic Type, capped so it stays inside the 96pt badge.
            Image(systemName: iconConfig.name)
                .font(.system(size: min(iconSize, 56)))
                .foregroundColor(iconConfig.color)
                .shadow(color: iconConfig.color.opacity(0.5), radius: 12)
        }
    }

    private var eventCategory: String {
        switch event {
        case .streakMilestone: return "Streak"
        case .phaseEvolution: return "Evolution"
        case .dailyGoalMet: return "Daily Goal"
        case .personalRecord: return "Personal Record"
        case .stepMilestone: return "Milestone"
        case .weeklyChallenge: return "Weekly Challenge"
        }
    }
}
