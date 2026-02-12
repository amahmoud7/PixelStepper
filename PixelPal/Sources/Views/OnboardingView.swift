import SwiftUI

/// 4-screen onboarding: Hook → Character → Evolution → Permission.
/// Rich gradients, large characters, staggered animations, branded CTAs.
struct OnboardingView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var currentStep: Int = 1
    @State private var selectedGender: Gender? = nil
    @State private var selectedStyle: String = "default"

    // Brand colors
    static let purple = Color(red: 0.49, green: 0.36, blue: 0.99)
    static let cyan = Color(red: 0.0, green: 0.83, blue: 1.0)
    static let mint = Color(red: 0.2, green: 0.78, blue: 0.35)

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

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentStep)

            VStack(spacing: 0) {
                // Progress bar
                OnboardingProgress(currentStep: currentStep, totalSteps: 4)
                    .padding(.top, 16)
                    .padding(.horizontal, 48)

                Spacer()

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
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
            }
        }
    }

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep += 1
        }
    }
}

// MARK: - Progress Bar

private struct OnboardingProgress: View {
    let currentStep: Int
    let totalSteps: Int

    private let purple = OnboardingView.purple

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep
                        ? AnyShapeStyle(LinearGradient(
                            colors: [purple, purple.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                          ))
                        : AnyShapeStyle(Color.white.opacity(0.15)))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
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

    private let frameTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            // Large character display with glow
            ZStack {
                // Ambient glow behind characters
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                OnboardingView.purple.opacity(0.2),
                                OnboardingView.purple.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(glowPulse ? 1.05 : 0.95)

                HStack(spacing: 24) {
                    Image(SpriteAssets.spriteName(gender: .male, state: .vital, frame: animFrame))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

                    Image(SpriteAssets.spriteName(gender: .female, state: .vital, frame: animFrame))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.6)
            .opacity(appeared ? 1.0 : 0)
            .onReceive(frameTimer) { _ in
                animFrame = animFrame == 1 ? 2 : 1
            }

            Spacer().frame(height: 32)

            // Title
            Text("Your steps tell a story")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 16)

            Spacer().frame(height: 12)

            // Subtitle
            Text("A living character that walks with you\non your Lock Screen all day.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(subtitleAppeared ? 1 : 0)
                .offset(y: subtitleAppeared ? 0 : 12)

            Spacer().frame(height: 28)

            // Dynamic Island mock
            DynamicIslandMock()
                .opacity(islandAppeared ? 1 : 0)
                .scaleEffect(islandAppeared ? 1 : 0.8)

            Spacer()

            // CTA
            OnboardingCTA(title: "Start My Journey") {
                onContinue()
            }
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 20)

            Spacer().frame(height: 50)
        }
        .padding(.horizontal, 24)
        .onAppear { staggerAnimations() }
    }

    private func staggerAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
            appeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            titleAppeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
            subtitleAppeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            islandAppeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            buttonAppeared = true
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowPulse = true
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
    @State private var maleScale: CGFloat = 1.0
    @State private var femaleScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            Text("Choose your character")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            Spacer().frame(height: 8)

            Text("They grow stronger every step you take")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 40)

            // Character cards
            HStack(spacing: 20) {
                CharacterCard(
                    gender: .male,
                    isSelected: selectedGender == .male,
                    scale: maleScale
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        selectedGender = .male
                        maleScale = 1.08
                        femaleScale = 1.0
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.15)) {
                        maleScale = 1.0
                    }
                }

                CharacterCard(
                    gender: .female,
                    isSelected: selectedGender == .female,
                    scale: femaleScale
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        selectedGender = .female
                        femaleScale = 1.08
                        maleScale = 1.0
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.15)) {
                        femaleScale = 1.0
                    }
                }
            }
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 24)

            Spacer()

            if selectedGender != nil {
                OnboardingCTA(title: "Continue") {
                    onContinue()
                }
                .opacity(buttonAppeared ? 1 : 0)
                .offset(y: buttonAppeared ? 0 : 20)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4)) {
                        buttonAppeared = true
                    }
                }
            }

            Spacer().frame(height: 50)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                cardsAppeared = true
            }
        }
    }
}

private struct CharacterCard: View {
    let gender: Gender
    let isSelected: Bool
    let scale: CGFloat
    let action: () -> Void

    @State private var animFrame: Int = 1
    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    private let purple = OnboardingView.purple

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 14) {
                ZStack {
                    // Glow ring when selected
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [purple.opacity(0.25), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 130, height: 130)
                    }

                    Image(SpriteAssets.spriteName(gender: gender, state: .vital, frame: animFrame))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }

                Text(gender.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected
                        ? purple.opacity(0.15)
                        : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected
                                ? purple.opacity(0.6)
                                : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(scale)
        }
        .onReceive(timer) { _ in
            animFrame = animFrame == 1 ? 2 : 1
        }
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

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var currentPhase: Int { Int(selectedPhase) }

    private var phaseInfo: (name: String, desc: String, color: Color, steps: String) {
        switch currentPhase {
        case 1: return ("Seedling", "Just getting started", .gray, "0 steps")
        case 2: return ("Growing", "Building momentum", Color(red: 0.0, green: 0.48, blue: 1.0), "25,000 steps")
        case 3: return ("Thriving", "In your stride", OnboardingView.purple, "75,000 steps")
        case 4: return ("Legendary", "Peak evolution", Color(red: 1.0, green: 0.6, blue: 0.0), "200,000 steps")
        default: return ("Seedling", "Just getting started", .gray, "0 steps")
        }
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
        VStack(spacing: 0) {
            Spacer().frame(height: 10)

            Text("Watch them evolve")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            Spacer().frame(height: 6)

            Text("Every step powers their growth")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 24)

            // Character with phase glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseInfo.color.opacity(0.25), phaseInfo.color.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Circle()
                    .stroke(phaseInfo.color.opacity(0.3), lineWidth: 2)
                    .frame(width: 160, height: 160)

                Image(SpriteAssets.spriteName(gender: selectedGender, state: avatarState, frame: animFrame))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }
            .scaleEffect(characterAppeared ? 1.0 : 0.5)
            .opacity(characterAppeared ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: currentPhase)
            .onReceive(timer) { _ in
                animFrame = animFrame == 1 ? 2 : 1
            }

            Spacer().frame(height: 12)

            // Phase badge
            HStack(spacing: 8) {
                Text("Phase \(currentPhase)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(phaseInfo.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(phaseInfo.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(phaseInfo.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(phaseInfo.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .animation(.easeInOut(duration: 0.3), value: currentPhase)

            Spacer().frame(height: 6)

            Text(phaseInfo.steps)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(phaseInfo.color.opacity(0.8))
                .animation(.easeInOut(duration: 0.3), value: currentPhase)

            Spacer().frame(height: 20)

            // Phase dots + slider
            VStack(spacing: 10) {
                HStack(spacing: 0) {
                    ForEach(1...4, id: \.self) { phase in
                        Circle()
                            .fill(phase <= currentPhase ? phaseColor(for: phase) : Color.white.opacity(0.15))
                            .frame(width: 10, height: 10)
                            .shadow(color: phase <= currentPhase ? phaseColor(for: phase).opacity(0.5) : .clear, radius: 4)
                        if phase < 4 { Spacer() }
                    }
                }
                .padding(.horizontal, 32)

                Slider(value: $selectedPhase, in: 1...4, step: 1)
                    .tint(phaseInfo.color)
                    .padding(.horizontal, 24)

                Text("Drag to preview")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
            .opacity(sliderAppeared ? 1 : 0)
            .offset(y: sliderAppeared ? 0 : 16)

            Spacer().frame(height: 20)

            // Feature highlights (merged from old differentiation screen)
            VStack(spacing: 12) {
                FeaturePill(icon: "arrow.up.circle.fill", text: "Evolves as you walk", color: OnboardingView.mint)
                FeaturePill(icon: "iphone.badge.play", text: "Lives on your Lock Screen", color: OnboardingView.cyan)
                FeaturePill(icon: "flame.fill", text: "Streaks, missions & rewards", color: .orange)
            }
            .opacity(featuresAppeared ? 1 : 0)
            .offset(y: featuresAppeared ? 0 : 12)

            Spacer()

            OnboardingCTA(title: "Continue") { onContinue() }

            Spacer().frame(height: 50)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.15)) { characterAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { sliderAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) { featuresAppeared = true }
        }
    }

    private func phaseColor(for phase: Int) -> Color {
        switch phase {
        case 1: return .gray
        case 2: return Color(red: 0.0, green: 0.48, blue: 1.0)
        case 3: return OnboardingView.purple
        case 4: return Color(red: 1.0, green: 0.6, blue: 0.0)
        default: return .gray
        }
    }
}

private struct FeaturePill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
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

    private let purple = OnboardingView.purple

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            // Character ready to go
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [purple.opacity(0.2), OnboardingView.cyan.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(glowPulse ? 1.06 : 0.94)

                if let gender = selectedGender {
                    Image(SpriteAssets.spriteName(gender: gender, state: .vital, frame: 1))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                }
            }
            .scaleEffect(avatarAppeared ? 1.0 : 0.5)
            .opacity(avatarAppeared ? 1 : 0)

            Spacer().frame(height: 28)

            Text("Ready to walk together?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            Spacer().frame(height: 10)

            Text("We only read your step count to\nbring your character to life.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

            Spacer().frame(height: 28)

            // Trust badges
            VStack(spacing: 10) {
                TrustBadge(icon: "lock.shield.fill", text: "100% on-device — nothing leaves your phone", color: OnboardingView.mint)
                TrustBadge(icon: "eye.slash.fill", text: "No accounts, no tracking, no ads", color: OnboardingView.cyan)
                TrustBadge(icon: "heart.fill", text: "Just steps — that's all we need", color: purple)
            }
            .opacity(badgesAppeared ? 1 : 0)
            .offset(y: badgesAppeared ? 0 : 16)

            Spacer()

            OnboardingCTA(title: "Continue") {
                completeOnboarding()
            }
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 20)

            Spacer().frame(height: 50)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { avatarAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { appeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) { badgesAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { buttonAppeared = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { glowPulse = true }
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Shared Components

private struct OnboardingCTA: View {
    let title: String
    let action: () -> Void

    private let purple = OnboardingView.purple
    private let cyan = OnboardingView.cyan

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [purple, cyan.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: purple.opacity(0.4), radius: 16, y: 6)
        }
        .padding(.horizontal, 32)
    }
}

private struct DynamicIslandMock: View {
    @State private var animFrame: Int = 1
    @State private var expanded = false
    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 10) {
            // Camera dot
            Circle()
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                .frame(width: 12, height: 12)

            if expanded {
                Image(SpriteAssets.spriteName(gender: .male, state: .vital, frame: animFrame))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                Text("4,231")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
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
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onReceive(timer) { _ in
            animFrame = animFrame == 1 ? 2 : 1
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8)) {
                expanded = true
            }
        }
    }
}
