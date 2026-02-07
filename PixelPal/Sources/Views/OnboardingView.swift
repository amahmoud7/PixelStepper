import SwiftUI

/// 6-screen onboarding flow (v1.1 spec).
/// 1. Identity Hook - "Your steps tell a story"
/// 2. Character Selection - Gender + starter style
/// 3. Phase Preview - See evolution phases with slider
/// 4. Truth Moment - Step benchmarks
/// 5. Differentiation - "Not another step counter"
/// 6. Permissions - HealthKit request
struct OnboardingView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var currentStep: Int = 1
    @State private var selectedGender: Gender? = nil
    @State private var selectedStyle: String = "default"

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.1, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.1, blue: 0.12)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(currentStep: currentStep, totalSteps: 6)
                    .padding(.top, 20)
                    .padding(.horizontal, 40)

                Spacer()

                // Current screen content
                Group {
                    switch currentStep {
                    case 1:
                        IdentityHookScreen(onContinue: { nextStep() })
                    case 2:
                        CharacterSelectionScreen(
                            selectedGender: $selectedGender,
                            selectedStyle: $selectedStyle,
                            onContinue: { nextStep() }
                        )
                    case 3:
                        PhasePreviewScreen(
                            selectedGender: selectedGender ?? .male,
                            onContinue: { nextStep() }
                        )
                    case 4:
                        TruthMomentScreen(onContinue: { nextStep() })
                    case 5:
                        DifferentiationScreen(onContinue: { nextStep() })
                    case 6:
                        PermissionsScreen(
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
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
}

// MARK: - Progress Indicator

private struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Screen 1: Identity Hook

private struct IdentityHookScreen: View {
    let onContinue: () -> Void
    @State private var animFrame: Int = 1
    private let frameTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            // Animated character preview (shows both genders side by side)
            HStack(spacing: 20) {
                Image(SpriteAssets.spriteName(gender: .male, state: .vital, frame: animFrame))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                Image(SpriteAssets.spriteName(gender: .female, state: .vital, frame: animFrame))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            }
            .onReceive(frameTimer) { _ in
                animFrame = animFrame == 1 ? 2 : 1
            }

            Text("Your steps tell a story")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Pixel Pace turns movement into a living character you see all day.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Mock Dynamic Island preview
            DynamicIslandPreview()
                .padding(.vertical, 20)

            Spacer().frame(height: 40)

            OnboardingButton(title: "Start my Pixel Pace", action: onContinue)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Screen 2: Character Selection

private struct CharacterSelectionScreen: View {
    @Binding var selectedGender: Gender?
    @Binding var selectedStyle: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose your character")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("This character grows when you move.")
                .font(.body)
                .foregroundColor(.gray)

            // Gender selection
            HStack(spacing: 40) {
                GenderButton(gender: .male, isSelected: selectedGender == .male) {
                    selectedGender = .male
                }
                GenderButton(gender: .female, isSelected: selectedGender == .female) {
                    selectedGender = .female
                }
            }
            .padding(.vertical, 20)

            if selectedGender != nil {
                OnboardingButton(title: "Continue", action: onContinue)
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(SpriteAssets.spriteName(gender: gender, state: .neutral, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                Text(gender.displayName)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Screen 3: Phase Preview

private struct PhasePreviewScreen: View {
    let selectedGender: Gender
    let onContinue: () -> Void

    @State private var selectedPhase: Double = 1
    @State private var animationFrame: Int = 1

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var currentPhase: Int {
        Int(selectedPhase)
    }

    private var phaseInfo: (name: String, description: String, color: Color, stepsRequired: String) {
        switch currentPhase {
        case 1:
            return ("Seedling", "Just getting started", .gray, "0 steps")
        case 2:
            return ("Growing", "Building momentum", .blue, "25,000 steps")
        case 3:
            return ("Thriving", "In your stride", .purple, "75,000 steps")
        case 4:
            return ("Legendary", "Peak evolution", .orange, "200,000 steps")
        default:
            return ("Seedling", "Just getting started", .gray, "0 steps")
        }
    }

    private var avatarState: AvatarState {
        switch currentPhase {
        case 1: return .low
        case 2: return .neutral
        case 3: return .vital
        case 4: return .vital
        default: return .low
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Watch your character evolve")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("The more you walk, the more they grow")
                .font(.body)
                .foregroundColor(.gray)

            Spacer().frame(height: 10)

            // Animated character
            ZStack {
                Circle()
                    .fill(phaseInfo.color.opacity(0.2))
                    .frame(width: 160, height: 160)

                Image(SpriteAssets.spriteName(gender: selectedGender, state: avatarState, frame: animationFrame))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
            .onReceive(timer) { _ in
                animationFrame = animationFrame == 1 ? 2 : 1
            }

            // Phase info
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: phaseIcon)
                        .foregroundColor(phaseInfo.color)
                    Text("Phase \(currentPhase)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("• \(phaseInfo.name)")
                        .font(.subheadline)
                        .foregroundColor(phaseInfo.color)
                }

                Text(phaseInfo.description)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(phaseInfo.stepsRequired)
                    .font(.caption2)
                    .foregroundColor(phaseInfo.color.opacity(0.8))
            }
            .padding(.vertical, 10)

            // Phase slider
            VStack(spacing: 12) {
                // Phase markers
                HStack {
                    ForEach(1...4, id: \.self) { phase in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(phase <= currentPhase ? phaseColor(for: phase) : Color.white.opacity(0.3))
                                .frame(width: 12, height: 12)
                            Text("\(phase)")
                                .font(.caption2)
                                .foregroundColor(phase <= currentPhase ? .white : .gray)
                        }
                        if phase < 4 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Slider
                Slider(value: $selectedPhase, in: 1...4, step: 1)
                    .tint(phaseInfo.color)
                    .padding(.horizontal, 20)

                Text("Drag to preview evolution phases")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.vertical, 10)

            Spacer().frame(height: 20)

            OnboardingButton(title: "Continue", action: onContinue)
        }
        .padding(.horizontal, 24)
    }

    private var phaseIcon: String {
        switch currentPhase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    private func phaseColor(for phase: Int) -> Color {
        switch phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }
}

// MARK: - Screen 4: Truth Moment

private struct TruthMomentScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Most people walk less than they think")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                StatRow(label: "Average American", value: "3,000-4,000", unit: "steps/day")
                StatRow(label: "Recommended", value: "7,500-10,000", unit: "steps/day")
                StatRow(label: "Highly active", value: "12,000+", unit: "steps/day")
            }
            .padding(.vertical, 20)

            Text("Pixel Pace shows the truth in real time.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 20)

            OnboardingButton(title: "Continue", action: onContinue)
        }
        .padding(.horizontal, 24)
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Screen 5: Differentiation

private struct DifferentiationScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple)

            Text("This isn't another step counter")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "arrow.up.circle.fill", color: .green,
                           text: "Evolves as you walk")
                FeatureRow(icon: "iphone.badge.play", color: .blue,
                           text: "Lives in Dynamic Island and Lock Screen")
                FeatureRow(icon: "bell.slash.fill", color: .orange,
                           text: "Motivation without notifications")
            }
            .padding(.vertical, 20)

            Spacer().frame(height: 20)

            OnboardingButton(title: "Continue", action: onContinue)
        }
        .padding(.horizontal, 24)
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Screen 6: Permissions

private struct PermissionsScreen: View {
    let selectedGender: Gender?
    let selectedStyle: String
    let healthManager: HealthKitManager

    var body: some View {
        VStack(spacing: 24) {
            if let gender = selectedGender {
                Image(SpriteAssets.spriteName(gender: gender, state: .vital, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }

            Text("Let Pixel Pace walk with you")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("We only use steps to evolve your character.\nNo data leaves your device.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Privacy assurance
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("100% Private")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.vertical, 10)

            Spacer().frame(height: 20)

            OnboardingButton(title: "Enable Steps") {
                completeOnboarding()
            }
        }
        .padding(.horizontal, 24)
    }

    private func completeOnboarding() {
        guard let gender = selectedGender else { return }

        // Create user profile
        let profile = UserProfile.createNew(gender: gender, starterStyle: selectedStyle)
        Task { @MainActor in
            PersistenceManager.shared.saveUserProfile(profile)
        }

        // Also save to legacy SharedData for backward compatibility
        SharedData.saveGender(gender)

        // Request HealthKit authorization
        healthManager.requestAuthorization { _ in }
    }
}

// MARK: - Shared Components

private struct OnboardingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.white, Color(white: 0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(14)
                .shadow(color: .white.opacity(0.2), radius: 8, y: 2)
        }
        .padding(.horizontal, 40)
    }
}

private struct DynamicIslandPreview: View {
    @State private var animFrame: Int = 1
    private let frameTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)

            Image(SpriteAssets.spriteName(gender: .male, state: .vital, frame: animFrame))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .onReceive(frameTimer) { _ in
                    animFrame = animFrame == 1 ? 2 : 1
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}
