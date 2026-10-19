import SwiftUI

/// Main watch screen: the character inside today's goal ring, with the step count.
struct TodayView: View {
    @EnvironmentObject private var store: WatchStore

    private var goalMet: Bool { store.progress >= 1 }
    private var ringColor: Color {
        goalMet ? WatchPalette.mint : WatchPalette.phaseColor(store.snapshot.phase)
    }

    private var energyCaption: String {
        switch store.state {
        case .vital: return "Vital · goal reached"
        case .neutral: return "Neutral"
        case .low: return "Low energy"
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(WatchPalette.track, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: store.progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: store.progress)
                WatchSprite(gender: store.snapshot.gender, state: store.state)
                    .padding(10)
            }
            .frame(maxHeight: .infinity)

            Text(store.todaySteps.formatted())
                .font(.system(.title2, design: .rounded).weight(.bold))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("of \(store.snapshot.dailyGoal.formatted()) · \(energyCaption)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your character, \(WatchPalette.phaseName(store.snapshot.phase)) phase")
        .accessibilityValue("\(store.todaySteps.formatted()) of \(store.snapshot.dailyGoal.formatted()) steps, \(energyCaption)")
    }
}
