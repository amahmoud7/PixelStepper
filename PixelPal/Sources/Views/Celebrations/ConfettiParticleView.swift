import SwiftUI

/// Sparkle particle system — ambient golden sparkles instead of confetti.
/// Uses Canvas + TimelineView for smooth 60fps rendering; a single still frame under Reduce Motion.
struct SparkleParticleView: View {
    let accentColor: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [Sparkle] = []
    @State private var startTime: Date = .now

    private let particleCount = 24

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                // Under Reduce Motion, draw one frozen moment where every sparkle is visible.
                let elapsed = reduceMotion ? 3.0 : timeline.date.timeIntervalSince(startTime)

                for particle in particles {
                    let age = elapsed - particle.delay
                    guard age > 0 else { continue }

                    let cycleAge = age.truncatingRemainder(dividingBy: particle.lifetime)
                    let phase = cycleAge / particle.lifetime

                    // Fade in, hold, fade out
                    let opacity: Double
                    if phase < 0.2 {
                        opacity = phase / 0.2
                    } else if phase > 0.7 {
                        opacity = (1.0 - phase) / 0.3
                    } else {
                        opacity = 1.0
                    }

                    // Scale pulse
                    let scale = 0.5 + 0.7 * sin(phase * .pi)

                    let x = particle.x * size.width
                    let y = particle.y * size.height

                    context.opacity = opacity * particle.baseOpacity
                    context.drawLayer { ctx in
                        let rect = CGRect(
                            x: x - particle.size * scale / 2,
                            y: y - particle.size * scale / 2,
                            width: particle.size * scale,
                            height: particle.size * scale
                        )

                        // Draw a 4-pointed star shape
                        var path = Path()
                        let cx = rect.midX
                        let cy = rect.midY
                        let r = rect.width / 2
                        let inner = r * 0.3

                        for i in 0..<4 {
                            let angle = Double(i) * .pi / 2 - .pi / 4
                            let outerX = cx + r * cos(angle)
                            let outerY = cy + r * sin(angle)
                            let innerAngle = angle + .pi / 4
                            let innerX = cx + inner * cos(innerAngle)
                            let innerY = cy + inner * sin(innerAngle)

                            if i == 0 {
                                path.move(to: CGPoint(x: outerX, y: outerY))
                            } else {
                                path.addLine(to: CGPoint(x: outerX, y: outerY))
                            }
                            path.addLine(to: CGPoint(x: innerX, y: innerY))
                        }
                        path.closeSubpath()

                        ctx.fill(path, with: .color(particle.color))
                    }
                }
            }
        }
        .onAppear {
            startTime = .now
            particles = (0..<particleCount).map { _ in
                Sparkle(accentColor: accentColor)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Sparkle {
    let x: Double
    let y: Double
    let size: Double
    let color: Color
    let delay: Double
    let lifetime: Double
    let baseOpacity: Double

    init(accentColor: Color) {
        x = Double.random(in: 0.05...0.95)
        y = Double.random(in: 0.08...0.55)
        size = Double.random(in: 6...14)
        delay = Double.random(in: 0...2)
        lifetime = Double.random(in: 1.5...3.0)
        baseOpacity = Double.random(in: 0.4...1.0)

        let colors: [Color] = [
            accentColor,
            Theme.gold,
            Theme.amber,
            .white
        ]
        color = colors.randomElement() ?? accentColor
    }
}
