import HealthKit
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let snapshot: WatchSnapshot

    var progress: Double { snapshot.goalProgress(steps: steps) }
    var state: AvatarState { AvatarLogic.determineState(steps: steps) }
}

struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), steps: 4_200, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task { completion(await makeEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            let entry = await makeEntry()
            // The watch app also reloads complications whenever its step count changes.
            let next = entry.date.addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func makeEntry() async -> StepsEntry {
        StepsEntry(date: Date(), steps: await todaySteps(), snapshot: WatchSharedStore.load() ?? .placeholder)
    }

    private func todaySteps() async -> Int {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(.stepCount),
            predicate: HKQuery.predicateForSamples(withStart: start, end: nil)
        )
        let descriptor = HKStatisticsQueryDescriptor(predicate: predicate, options: .cumulativeSum)
        let statistics = (try? await descriptor.result(for: HKHealthStore())) ?? nil
        return Int(statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
    }
}

// MARK: - Views

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StepsEntry

    private var sprite: some View {
        Image(decorative: SpriteAssets.spriteName(gender: entry.snapshot.gender, state: entry.state, frame: 1))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: entry.progress) {
                EmptyView()
            } currentValueLabel: {
                sprite.padding(2)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .accessibilityLabel("\(entry.steps.formatted()) of \(entry.snapshot.dailyGoal.formatted()) steps")

        case .accessoryRectangular:
            HStack(spacing: 6) {
                sprite.frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.steps.formatted()) steps")
                        .font(.headline)
                        .widgetAccentable()
                    ProgressView(value: entry.progress)
                    Text(entry.progress >= 1 ? "Goal reached" : "\(max(0, entry.snapshot.dailyGoal - entry.steps).formatted()) to goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

        case .accessoryInline:
            Label("\(entry.steps.formatted()) steps", systemImage: "figure.walk")

        case .accessoryCorner:
            Image(systemName: "figure.walk")
                .font(.title3)
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: entry.progress) {
                        Text("Steps")
                    } currentValueLabel: {
                        Text(entry.steps.formatted())
                    }
                }
                .accessibilityLabel("\(entry.steps.formatted()) steps")

        default:
            sprite
        }
    }
}

private extension View {
    /// watchOS 10 expects a container background on every complication.
    @ViewBuilder
    func complicationBackground() -> some View {
        if #available(watchOS 10.0, *) {
            containerBackground(.clear, for: .widget)
        } else {
            self
        }
    }
}

// MARK: - Widget

@main
struct PixelStepperComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PixelStepperComplication", provider: StepsProvider()) { entry in
            ComplicationView(entry: entry)
                .complicationBackground()
        }
        .configurationDisplayName("Pixel Stepper")
        .description("Your character and today's steps.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}
