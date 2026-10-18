import SwiftUI

/// Animated splash screen — seamless transition from iOS launch screen into the app.
/// Deep indigo background matches LaunchBackground color set for zero-flash handoff.
struct SplashScreenView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var glowScale: CGFloat = 0.6
    @State private var glowOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoOffset: CGFloat = 12
    @State private var characterOpacity: Double = 0
    @State private var characterScale: CGFloat = 0.7
    @State private var subtitleOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0
    @State private var exitTask: Task<Void, Never>?
    @State private var animFrame: Int = 1

    private let purple = Theme.purple
    private let cyan = Theme.cyan

    var body: some View {
        ZStack {
            // Background — matches LaunchBackground color
            LinearGradient(
                colors: [Theme.bgDeep, Theme.bgMid, Theme.bgDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                // Ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                purple.opacity(0.25),
                                purple.opacity(0.08),
                                cyan.opacity(0.03),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .scaleEffect(reduceMotion ? 1 : glowScale)
                    .opacity(glowOpacity)

                // Rotating ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [purple.opacity(0.4), cyan.opacity(0.2), .clear, .clear, purple.opacity(0.4)],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(ringRotation))
                    .opacity(ringOpacity)

                // Second ring (counter-rotate)
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [cyan.opacity(0.3), .clear, .clear, purple.opacity(0.2), cyan.opacity(0.3)],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-ringRotation * 0.7))
                    .opacity(ringOpacity * 0.6)
            }
            .accessibilityHidden(true)

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Characters
                HStack(spacing: Space.l) {
                    Image(decorative: SpriteAssets.spriteName(gender: .male, state: .vital, frame: animFrame))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)

                    Image(decorative: SpriteAssets.spriteName(gender: .female, state: .vital, frame: animFrame))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                }
                .scaleEffect(reduceMotion ? 1 : characterScale)
                .opacity(characterOpacity)

                Spacer().frame(height: 32)

                // App name
                appName
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, Space.screen)
                    .opacity(logoOpacity)
                    .offset(y: reduceMotion ? 0 : logoOffset)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Pixel Stepper")
                .accessibilityAddTraits(.isHeader)

                Spacer().frame(height: 10)

                // Tagline
                Text("Walk. Evolve. Grow.")
                    .font(.ppBody)
                    .foregroundColor(Theme.textTertiary)
                    .tracking(2)
                    .opacity(subtitleOpacity)

                Spacer()
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        // Two-frame sprite toggle, cancelled automatically when the splash goes away.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Motion.spriteFrameInterval * 1_000_000_000))
                if Task.isCancelled { break }
                animFrame = animFrame == 1 ? 2 : 1
            }
        }
        .onAppear { runSequence() }
        .onDisappear { exitTask?.cancel() }
    }

    /// Two-tone wordmark built by Text interpolation (`Text + Text` is deprecated).
    private var appName: Text {
        let pixel = Text("PIXEL")
            .font(.ppLargeTitle)
            .foregroundColor(Theme.textPrimary)
            .tracking(6)
        let stepper = Text(" STEPPER")
            .font(.ppLargeTitle)
            .foregroundColor(purple)
            .tracking(6)
        return Text("\(pixel)\(stepper)")
    }

    private func runSequence() {
        // Phase 1: Glow fades in
        withMotion(Motion.smooth, reduceMotion: reduceMotion) {
            glowOpacity = 1.0
            glowScale = 1.0
        }

        // Phase 2: Rings appear and rotate (rotation skipped under Reduce Motion)
        withMotion(Motion.smooth.delay(0.2), reduceMotion: reduceMotion) {
            ringOpacity = 1.0
        }
        if !reduceMotion {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }

        // Phase 3: Characters spring in
        withMotion(Motion.bouncy.delay(0.3), reduceMotion: reduceMotion) {
            characterOpacity = 1.0
            characterScale = 1.0
        }

        // Phase 4: Logo slides up
        withMotion(Motion.smooth.delay(0.5), reduceMotion: reduceMotion) {
            logoOpacity = 1.0
            logoOffset = 0
        }

        // Phase 5: Subtitle
        withMotion(Motion.smooth.delay(0.7), reduceMotion: reduceMotion) {
            subtitleOpacity = 1.0
        }

        // Phase 6: Hold for a beat, then exit
        exitTask?.cancel()
        exitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            withMotion(Motion.exit, reduceMotion: reduceMotion) {
                if !reduceMotion { exitScale = 1.08 }
                exitOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}
