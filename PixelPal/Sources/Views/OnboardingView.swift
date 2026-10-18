import SwiftUI

/// 4-screen onboarding: Hook → Character → Evolution → Permission.
/// Rich gradients, large characters, staggered animations, branded CTAs.
struct OnboardingView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentStep: Int = 1
    @State private var selectedGender: Gender? = nil
    @State private var selectedStyle: String = "default"

    private var backgroundGradient: LinearGradient {
        let colors: [Color] = {
            switch currentStep {
            case 1: return [
                Color(red: 0.05, green: 0.02, blue: 0.15),
                Color(red: 0.12, green: 0.04, blue: 0.24),
                Color(red: 0.06, green: 0.02, blue: 0.16)
            ]
            case 2: return [
                Color(red: 0.08, green: 0.03, blue: 0.18),
                Color(red: 0.16, green: 0.05, blue: 0.28),
                Color(red: 0.08, green: 0.03, blue: 0.18)
            ]
            case 3: return [
                Color(red: 0.10, green: 0.03, blue: 0.20),
                Color(red: 0.18, green: 0.06, blue: 0.30),
                Color(red: 0.06, green: 0.04, blue: 0.16)
            ]
            case 4: return [
                Color(red: 0.06, green: 0.04, blue: 0.16),
                Color(red: 0.12, green: 0.06, blue: 0.22),
                Color(red: 0.04, green: 0.06, blue: 0.14)
            ]
            default: return [
                Color(red: 0.05, green: 0.02, blue: 0.15),
                Color(red: 0.12, green: 0.04, blue: 0.24),
                Color(red: 0.06, green: 0.02, blue: 0.16)
            ]
            }
        }()

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var pageTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
                .motion(Motion.smooth, value: currentStep)

            VStack(spacing: 0) {
                // Progress bar
                OnboardingProgress(currentStep: currentStep, totalSteps: 4)
                    .padding(.top, Space.l)
                    .padding(.horizontal, 48)

                Group {
                    switch currentStep {
                    case 1:
                        HookScreen(onContinue: { nextStep() })
                    case 2:
                        CharacterScreen(
                            selectedGender: $selectedGender,
                            onContinue: { nextStep() }
                        )
                    case 3:
                        EvolutionScreen(
                            selectedGender: selectedGender ?? .male,
                            onContinue: { nextStep() }
                        )
                    case 4:
                        PermissionScreen(
                            selectedGender: selectedGender,
                            selectedStyle: selectedStyle,
                            healthManager: healthManager
                        )
                    default:
                        EmptyView()
                    }
                }
                .transition(pageTransition)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Pages scroll, so allow large sizes; cap only the extreme accessibility sizes.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func nextStep() {
        withMotion(Motion.smooth, reduceMotion: reduceMotion) {
            currentStep += 1
        }
    }
}

// MARK: - Page Layout

/// Scrollable page body (centered when it fits) with the CTA pinned to the bottom,
/// so nothing clips on small screens or at larger text sizes.
private struct OnboardingPage<Content: View, Footer: View>: View {
    let content: Content
    let footer: Footer

    init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.horizontal, Space.xl)
                        .padding(.vertical, Space.l)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }

            footer
                .padding(.top, Space.s)
                .padding(.bottom, Space.xl)
        }
    }
}

/// Fade-and-slide entrance that skips the movement under Reduce Motion.
private struct EntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isVisible: Bool
    let offset: CGFloat
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : offset)
            .scaleEffect(isVisible || reduceMotion ? 1 : scale)
    }
}

private extension View {
    func entrance(_ isVisible: Bool, offset: CGFloat = 0, scale: CGFloat = 1) -> some View {
        modifier(EntranceModifier(isVisible: isVisible, offset: offset, scale: scale))
    }

    /// Toggles a two-frame sprite animation while the view is on screen.
    func spriteFrameLoop(_ frame: Binding<Int>, every seconds: Double = Motion.spriteFrameInterval) -> some View {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        return task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: nanoseconds)
                frame.wrappedValue = frame.wrappedValue == 1 ? 2 : 1
            }
        }
    }
}

// MARK: - Progress Bar

private struct OnboardingProgress: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Theme.purple, Theme.purple.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                          ))
                        : AnyShapeStyle(Color.white.opacity(0.15)))
                    .frame(height: 3)
                    .motion(Motion.snappy, value: currentStep)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
    }
}

// MARK: - Screen 1: Hook

private struct HookScreen: View {
    let onContinue: () -> Void

    @State private var animFrame: Int = 1
    @State private var appeared = false
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var islandAppeared = false
    @State private var buttonAppeared = false
    @State private var glowPulse = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingPage {
            VStack(spacing: 0) {
                // Large character display with glow
                ZStack {
                    // Ambient glow behind characters
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.purple.opacity(0.2),
                                    Theme.purple.opacity(0.05),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .scaleEffect(glowPulse ? 1.05 : 0.95)
                        .ambientLoop($glowPulse, animation: Motion.ambient())

                    HStack(spacing: Space.xl) {
                        Image(decorative: SpriteAssets.spriteName(gender: .male, state: .vital, frame: animFrame))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        Image(decorative: SpriteAssets.spriteName(gender: .female, state: .vital, frame: animFrame))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                    }
                }
                .frame(height: 240)
                .entrance(appeared, scale: 0.6)
                .spriteFrameLoop($animFrame)

                Spacer().frame(height: Space.xl)

                // Title
                Text("Your steps tell a story")
                    .font(.ppTitle)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(titleAppeared, offset: 16)

                Spacer().frame(height: Space.m)

                // Subtitle
                Text("A living character that walks with you on your Lock Screen all day.")
                    .font(.ppBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(subtitleAppeared, offset: 12)

                Spacer().frame(height: 28)

                // Dynamic Island mock
                DynamicIslandMock()
                    .entrance(islandAppeared, scale: 0.8)
            }
        } footer: {
            OnboardingCTA(title: "Start my journey") {
                onContinue()
            }
            .entrance(buttonAppeared, offset: 20)
        }
        .onAppear { staggerAnimations() }
    }

    private func staggerAnimations() {
        withMotion(Motion.bouncy, reduceMotion: reduceMotion) {
            appeared = true
        }
        withMotion(Motion.staggered(3), reduceMotion: reduceMotion) {
            titleAppeared = true
        }
        withMotion(Motion.staggered(5), reduceMotion: reduceMotion) {
            subtitleAppeared = true
        }
        withMotion(Motion.staggered(7), reduceMotion: reduceMotion) {
            islandAppeared = true
        }
        withMotion(Motion.staggered(9), reduceMotion: reduceMotion) {
            buttonAppeared = true
        }
    }
}

// MARK: - Screen 2: Character Selection

private struct CharacterScreen: View {
    @Binding var selectedGender: Gender?
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var cardsAppeared = false
    @State private var buttonAppeared = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingPage {
            VStack(spacing: 0) {
                Text("Choose your character")
                    .font(.ppTitle)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(appeared, offset: 16)

                Spacer().frame(height: Space.s)

                Text("They grow stronger every step you take")
                    .font(.ppBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .entrance(appeared)

                Spacer().frame(height: 40)

                // Character cards
                HStack(spacing: Space.screen) {
                    CharacterCard(
                        gender: .male,
                        isSelected: selectedGender == .male
                    ) {
                        select(.male)
                    }

                    CharacterCard(
                        gender: .female,
                        isSelected: selectedGender == .female
                    ) {
                        select(.female)
                    }
                }
                .entrance(cardsAppeared, offset: 24)
            }
        } footer: {
            if selectedGender != nil {
                OnboardingCTA(title: "Continue") {
                    onContinue()
                }
                .entrance(buttonAppeared, offset: 20)
                .onAppear {
                    withMotion(Motion.smooth, reduceMotion: reduceMotion) {
                        buttonAppeared = true
                    }
                }
            } else {
                // Reserve the CTA's height so the layout doesn't jump on selection.
                Color.clear.frame(height: 52)
            }
        }
        .onAppear {
            withMotion(Motion.smooth, reduceMotion: reduceMotion) {
                appeared = true
            }
            withMotion(Motion.staggered(3), reduceMotion: reduceMotion) {
                cardsAppeared = true
            }
        }
    }

    private func select(_ gender: Gender) {
        withMotion(Motion.bouncy, reduceMotion: reduceMotion) {
            selectedGender = gender
        }
    }
}

private struct CharacterCard: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void

    @State private var animFrame: Int = 1

    var body: some View {
        Button(action: {
            Haptics.select()
            action()
        }) {
            VStack(spacing: 14) {
                ZStack {
                    // Glow ring when selected
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Theme.purple.opacity(0.25), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 130, height: 130)
                    }

                    Image(decorative: SpriteAssets.spriteName(gender: gender, state: .vital, frame: animFrame))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
                .frame(height: 130)

                Text(gender.displayName)
                    .font(.ppBody.weight(.semibold))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
            }
            .padding(.vertical, Space.screen)
            .padding(.horizontal, Space.m)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected
                        ? Theme.purple.opacity(0.15)
                        : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected
                                ? Theme.purple.opacity(0.6)
                                : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PPPressableStyle())
        .accessibilityLabel(gender.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .spriteFrameLoop($animFrame)
    }
}

// MARK: - Screen 3: Evolution Preview

private struct EvolutionScreen: View {
    let selectedGender: Gender
    let onContinue: () -> Void

    @State private var selectedPhase: Double = 1
    @State private var animFrame: Int = 1
    @State private var appeared = false
    @State private var characterAppeared = false
    @State private var sliderAppeared = false
    @State private var featuresAppeared = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentPhase: Int { Int(selectedPhase) }

    private var phaseColor: Color { Theme.phaseColor(currentPhase) }

    /// Phase color for small text; the brand purple is too dark at caption sizes.
    private var phaseTextColor: Color {
        currentPhase == 3 ? Theme.purpleText : phaseColor
    }

    /// Weekly target to reach this phase, from the same thresholds the app uses.
    private var phaseSteps: String {
        guard currentPhase > 1 else { return "0 steps" }
        let threshold = PhaseCalculator.nextThreshold(for: currentPhase - 1)
        return "\(threshold.formatted()) steps in a week"
    }

    private var avatarState: AvatarState {
        switch currentPhase {
        case 1: return .low
        case 2: return .neutral
        case 3, 4: return .vital
        default: return .low
        }
    }

    var body: some View {
        OnboardingPage {
            VStack(spacing: 0) {
                Text("Watch them evolve")
                    .font(.ppTitle)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(appeared, offset: 16)

                Spacer().frame(height: 6)

                Text("Every step powers their growth")
                    .font(.ppBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .entrance(appeared)

                Spacer().frame(height: Space.xl)

                // Character with phase glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [phaseColor.opacity(0.25), phaseColor.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)

                    Circle()
                        .stroke(phaseColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)

                    Image(decorative: SpriteAssets.spriteName(gender: selectedGender, state: avatarState, frame: animFrame))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                }
                .entrance(characterAppeared, scale: 0.5)
                .motion(Motion.snappy, value: currentPhase)
                .spriteFrameLoop($animFrame)

                Spacer().frame(height: Space.m)

                // Phase badge
                HStack(spacing: Space.s) {
                    Text("Phase \(currentPhase)")
                        .font(.ppBody.weight(.bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(Theme.phaseName(currentPhase))
                        .font(.ppBody)
                        .foregroundColor(phaseTextColor)
                }
                .padding(.horizontal, Space.l)
                .padding(.vertical, Space.s)
                .background(
                    Capsule()
                        .fill(phaseColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(phaseColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .motion(Motion.snappy, value: currentPhase)
                .accessibilityElement(children: .combine)

                Spacer().frame(height: 6)

                Text(phaseSteps)
                    .font(.ppCaption)
                    .foregroundColor(phaseTextColor)
                    .motion(Motion.snappy, value: currentPhase)

                Spacer().frame(height: Space.screen)

                // Phase dots + slider
                VStack(spacing: 10) {
                    HStack(spacing: 0) {
                        ForEach(1...4, id: \.self) { phase in
                            Circle()
                                .fill(phase <= currentPhase ? Theme.phaseColor(phase) : Color.white.opacity(0.15))
                                .frame(width: 10, height: 10)
                                .shadow(color: phase <= currentPhase ? Theme.phaseColor(phase).opacity(0.5) : .clear, radius: 4)
                            if phase < 4 { Spacer() }
                        }
                    }
                    .padding(.horizontal, 32)
                    .accessibilityHidden(true)

                    Slider(value: $selectedPhase, in: 1...4, step: 1)
                        .tint(phaseColor)
                        .padding(.horizontal, Space.xl)
                        .accessibilityLabel("Preview phase")
                        .accessibilityValue("Phase \(currentPhase), \(Theme.phaseName(currentPhase))")

                    Text("Drag to preview")
                        .font(.ppMicro)
                        .foregroundColor(Theme.textTertiary)
                        .accessibilityHidden(true)
                }
                .entrance(sliderAppeared, offset: 16)
                .onChange(of: currentPhase) { _ in
                    Haptics.select()
                }

                Spacer().frame(height: Space.screen)

                // Feature highlights (merged from old differentiation screen)
                VStack(spacing: Space.m) {
                    FeaturePill(icon: "arrow.up.circle.fill", text: "Evolves as you walk", color: Theme.mint)
                    FeaturePill(icon: "iphone.badge.play", text: "Lives on your Lock Screen", color: Theme.cyan)
                    FeaturePill(icon: "flame.fill", text: "Streaks, missions & rewards", color: Theme.amber)
                }
                .entrance(featuresAppeared, offset: 12)
            }
        } footer: {
            OnboardingCTA(title: "Continue") { onContinue() }
        }
        .onAppear {
            withMotion(Motion.smooth, reduceMotion: reduceMotion) { appeared = true }
            withMotion(Motion.staggered(2, Motion.bouncy), reduceMotion: reduceMotion) { characterAppeared = true }
            withMotion(Motion.staggered(5), reduceMotion: reduceMotion) { sliderAppeared = true }
            withMotion(Motion.staggered(7), reduceMotion: reduceMotion) { featuresAppeared = true }
        }
    }
}

private struct FeaturePill: View {
    let icon: String
    let text: String
    let color: Color

    @ScaledMetric(relativeTo: .subheadline) private var iconWidth: CGFloat = 24

    var body: some View {
        HStack(spacing: Space.m) {
            Image(systemName: icon)
                .font(.ppBody.weight(.semibold))
                .foregroundColor(color)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            Text(text)
                .font(.ppBody)
                .foregroundColor(Theme.textPrimary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, Space.screen)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Screen 4: Permission

private struct PermissionScreen: View {
    let selectedGender: Gender?
    let selectedStyle: String
    let healthManager: HealthKitManager

    @State private var appeared = false
    @State private var avatarAppeared = false
    @State private var badgesAppeared = false
    @State private var buttonAppeared = false
    @State private var glowPulse = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingPage {
            VStack(spacing: 0) {
                // Character ready to go
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.purple.opacity(0.2), Theme.cyan.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 110
                            )
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(glowPulse ? 1.06 : 0.94)
                        .ambientLoop($glowPulse, animation: Motion.ambient())

                    if let gender = selectedGender {
                        Image(decorative: SpriteAssets.spriteName(gender: gender, state: .vital, frame: 1))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                    }
                }
                .frame(height: 200)
                .entrance(avatarAppeared, scale: 0.5)

                Spacer().frame(height: 28)

                Text("Ready to walk together?")
                    .font(.ppTitle)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(appeared, offset: 16)

                Spacer().frame(height: 10)

                Text("We only read your step count to bring your character to life.")
                    .font(.ppBody)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(appeared, offset: 12)

                Spacer().frame(height: 28)

                // Trust badges
                VStack(spacing: 10) {
                    TrustBadge(icon: "lock.shield.fill", text: "100% on-device — nothing leaves your phone", color: Theme.mint)
                    TrustBadge(icon: "eye.slash.fill", text: "No accounts, no tracking, no ads", color: Theme.cyan)
                    TrustBadge(icon: "heart.fill", text: "Just steps — that's all we need", color: Theme.purpleText)
                }
                .entrance(badgesAppeared, offset: 16)
            }
        } footer: {
            OnboardingCTA(title: "Continue") {
                completeOnboarding()
            }
            .entrance(buttonAppeared, offset: 20)
        }
        .onAppear {
            withMotion(Motion.bouncy, reduceMotion: reduceMotion) { avatarAppeared = true }
            withMotion(Motion.staggered(3), reduceMotion: reduceMotion) { appeared = true }
            withMotion(Motion.staggered(6), reduceMotion: reduceMotion) { badgesAppeared = true }
            withMotion(Motion.staggered(9), reduceMotion: reduceMotion) { buttonAppeared = true }
        }
    }

    private func completeOnboarding() {
        guard let gender = selectedGender else { return }

        let profile = UserProfile.createNew(gender: gender, starterStyle: selectedStyle)
        Task { @MainActor in
            PersistenceManager.shared.saveUserProfile(profile)
        }

        SharedData.saveGender(gender)
        healthManager.requestAuthorization { _ in }

        Task {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                await MainActor.run {
                    NotificationManager.shared.scheduleAll()
                }
            }
        }
    }
}

private struct TrustBadge: View {
    let icon: String
    let text: String
    let color: Color

    @ScaledMetric(relativeTo: .footnote) private var iconWidth: CGFloat = 24

    var body: some View {
        HStack(spacing: Space.m) {
            Image(systemName: icon)
                .font(.ppBody)
                .foregroundColor(color)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            Text(text)
                .font(.ppRowTitle.weight(.medium))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared Components

private struct OnboardingCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
        }
        .buttonStyle(PPPrimaryButtonStyle(colors: [Theme.purple, Theme.purpleDeep]))
        .padding(.horizontal, 32)
    }
}

private struct DynamicIslandMock: View {
    @State private var animFrame: Int = 1
    @State private var expanded = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            // Camera dot
            Circle()
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                .frame(width: 12, height: 12)

            if expanded {
                Image(decorative: SpriteAssets.spriteName(gender: .male, state: .vital, frame: animFrame))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                // Fixed size: this mimics the hardware Dynamic Island, which doesn't scale.
                Text("4,231")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary.opacity(0.9))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, expanded ? 18 : 14)
        .padding(.vertical, expanded ? 10 : 8)
        .background(
            Capsule()
                .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
                .overlay(
                    Capsule()
                        .stroke(Theme.stroke, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dynamic Island preview showing your character and today's steps")
        .spriteFrameLoop($animFrame)
        .onAppear {
            withMotion(Motion.bouncy.delay(0.8), reduceMotion: reduceMotion) {
                expanded = true
            }
        }
    }
}
