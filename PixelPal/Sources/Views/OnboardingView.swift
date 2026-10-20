import SwiftUI

/// 3-screen onboarding: Hook → Character → Permissions.
/// Rich gradients, large characters, staggered animations, branded CTAs.
/// The primary CTA is always the bottom-most button on each page (the UI test relies on it).
struct OnboardingView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentStep: Int = 1
    @State private var selectedGender: Gender? = nil
    @State private var selectedStyle: String = "default"
    /// Direction of the last page change, so Back slides the opposite way.
    @State private var isGoingBack = false

    private let totalSteps = 3

    private var backgroundGradient: LinearGradient {
        let colors: [Color] = {
            switch currentStep {
            case 2: return [
                Color(red: 0.08, green: 0.03, blue: 0.18),
                Color(red: 0.16, green: 0.05, blue: 0.28),
                Color(red: 0.08, green: 0.03, blue: 0.18)
            ]
            case 3: return [
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
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: isGoingBack ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: isGoingBack ? .trailing : .leading).combined(with: .opacity)
        )
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
                .motion(Motion.smooth, value: currentStep)

            VStack(spacing: 0) {
                // Back + page indicator
                HStack(spacing: Space.s) {
                    if currentStep > 1 {
                        Button(action: previousStep) {
                            Image(systemName: "chevron.left")
                                .font(.ppSection)
                                .foregroundColor(Theme.textSecondary)
                                .minTapTarget()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Back")
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }

                    OnboardingProgress(currentStep: currentStep, totalSteps: totalSteps)

                    // Balances the Back button so the indicator stays centered.
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.top, Space.s)
                .padding(.horizontal, Space.s)

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
                        PermissionScreen(
                            selectedGender: selectedGender,
                            selectedStyle: selectedStyle
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
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func nextStep() {
        guard currentStep < totalSteps else { return }
        isGoingBack = false
        // Next runloop, so the outgoing page renders with the new direction before it's removed.
        DispatchQueue.main.async {
            withMotion(Motion.smooth, reduceMotion: reduceMotion) {
                currentStep += 1
            }
        }
    }

    private func previousStep() {
        guard currentStep > 1 else { return }
        Haptics.soft()
        isGoingBack = true
        DispatchQueue.main.async {
            withMotion(Motion.smooth, reduceMotion: reduceMotion) {
                currentStep -= 1
            }
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
                VStack(spacing: Space.s) {
                    Text("A living character that walks with you on your Lock Screen all day.")
                    Text("Walk more, and your character's aura evolves through 4 phases.")
                }
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

// MARK: - Screen 3: Permissions

/// Primes both permissions before any system prompt appears:
/// notifications are requested on Continue, then the profile is saved and
/// ContentView asks for Health access once the main app appears.
private struct PermissionScreen: View {
    let selectedGender: Gender?
    let selectedStyle: String

    @State private var appeared = false
    @State private var avatarAppeared = false
    @State private var badgesAppeared = false
    @State private var buttonAppeared = false
    @State private var glowPulse = false
    @State private var isFinishing = false

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

                Spacer().frame(height: 28)

                // Permission primers
                VStack(spacing: 10) {
                    TrustBadge(
                        icon: "heart.fill",
                        text: "Pixel Stepper reads your step count from Apple Health. Nothing leaves your phone.",
                        color: Theme.mint
                    )
                    TrustBadge(
                        icon: "bell.fill",
                        text: "One gentle reminder a day, at most.",
                        color: Theme.purpleText
                    )
                }
                .entrance(badgesAppeared, offset: 16)
            }
        } footer: {
            OnboardingCTA(title: "Continue") {
                completeOnboarding()
            }
            .disabled(isFinishing)
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
        guard let gender = selectedGender, !isFinishing else { return }
        isFinishing = true

        Task { @MainActor in
            // The only notification request in the app; asked before the profile save so the
            // Health sheet (shown by ContentView after the save) never stacks on top of it.
            if !LaunchFlags.uiTest {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    NotificationManager.shared.scheduleAll()
                }
            }

            let profile = UserProfile.createNew(gender: gender, starterStyle: selectedStyle)
            SharedData.saveGender(gender)
            PersistenceManager.shared.saveUserProfile(profile)
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
                .font(.ppBody)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, Space.m)
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
