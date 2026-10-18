import SwiftUI

/// Time Freeze Step Moment — clock-centered, ambient rings, purple CTA, meditative layout.
struct StepMomentView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 56
    @ScaledMetric(relativeTo: .largeTitle) private var stepsSize: CGFloat = 52
    @State private var isShowing = false
    @State private var isDismissing = false
    @State private var ringScale: CGFloat = 0.8
    @State private var dismissTask: Task<Void, Never>?

    private var steps: Int { Int(healthManager.currentSteps) }

    private var progress: Double {
        min(Double(healthManager.currentSteps) / 7500.0, 1.0)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.06),
                    Color(red: 0.08, green: 0.03, blue: 0.12),
                    Color(red: 0.04, green: 0.02, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .opacity(isShowing ? 1 : 0)

            // Ambient clock rings
            Group {
                Circle()
                    .stroke(Theme.purple.opacity(0.06), lineWidth: 1)
                    .frame(width: 280, height: 280)

                Circle()
                    .stroke(Theme.purple.opacity(0.04), lineWidth: 1)
                    .frame(width: 220, height: 220)

                Circle()
                    .stroke(Theme.purple.opacity(0.02), lineWidth: 1)
                    .frame(width: 340, height: 340)
            }
            .scaleEffect(reduceMotion ? 1 : ringScale)
            .offset(y: -30)
            .opacity(isShowing ? 1 : 0)
            .accessibilityHidden(true)

            // Content: centered when it fits, scrolls on small screens / large text
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    content
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
            }
            .opacity(isShowing ? 1.0 : 0)
            .scaleEffect(isShowing || reduceMotion ? 1.0 : 0.95)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            appState.stepMomentManager.captureMoment(
                steps: steps,
                state: appState.avatarState.rawValue,
                phase: appState.currentPhase
            )

            withMotion(Motion.smooth, reduceMotion: reduceMotion) {
                isShowing = true
            }
            withMotion(Motion.reveal, reduceMotion: reduceMotion) {
                ringScale = 1.0
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Space.l)

            // Time display
            Text(Date(), style: .time)
                .font(.system(size: timeSize, weight: .ultraLight, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .tracking(4)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, Space.screen)

            Text("STEP MOMENT")
                .font(.ppOverline)
                .tracking(3)
                .foregroundColor(Theme.purpleText)
                .padding(.top, Space.xs)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: Space.l)

            // Avatar
            AvatarView(
                state: appState.avatarState,
                gender: appState.gender,
                phase: appState.currentPhase,
                size: 140
            )
            .background(
                Circle()
                    .fill(Theme.purple.opacity(0.08))
                    .frame(width: 100, height: 100)
            )

            Spacer()
                .frame(height: Space.l)

            // Steps
            VStack(spacing: 0) {
                Text(steps.formatted())
                    .font(.system(size: stepsSize, weight: .black, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .numericRoll(value: steps)
                    .padding(.horizontal, Space.screen)

                Text("steps at this moment")
                    .font(.ppBody)
                    .foregroundColor(Theme.textTertiary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(steps.formatted()) steps at this moment")

            Spacer()
                .frame(height: Space.xl)

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.purple, Theme.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 4)
                            .shadow(color: Theme.purple.opacity(0.4), radius: 4)
                    }
                }
                .frame(height: 4)
                .motion(Motion.number, value: progress)
                .padding(.horizontal, 60)
                .accessibilityHidden(true)

                Text("\(Int(progress * 100))% of daily goal")
                    .font(.ppMicro)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer(minLength: Space.xl)

            // Share CTA — purple
            Button {
                Haptics.tap()
                shareNow()
            } label: {
                Text("Share This Moment")
            }
            .buttonStyle(PPPrimaryButtonStyle())
            .padding(.horizontal, 40)

            // Dismiss
            Button {
                Haptics.soft()
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(.ppRowTitle)
                    .foregroundColor(Theme.textTertiary)
                    .padding(.horizontal, Space.l)
                    .minTapTarget()
            }
            .buttonStyle(.plain)
            .padding(.top, Space.s)
            .padding(.bottom, Space.l)
        }
    }

    private func shareNow() {
        dismiss()
        appState.showShareSheet = true
    }

    private func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        withMotion(Motion.exit, reduceMotion: reduceMotion) {
            isShowing = false
        }
        // Not cancelled on disappear: hiding the moment is idempotent and must still happen
        // if the overlay is removed mid-exit (e.g. a celebration takes over).
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            appState.showStepMoment = false
        }
    }
}
