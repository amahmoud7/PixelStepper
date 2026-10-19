import Foundation
import HealthKit
import WatchConnectivity
import WidgetKit

/// Watch-side state: steps straight from HealthKit, plus the character/phase/streak the iPhone shares.
@MainActor
final class WatchStore: NSObject, ObservableObject {
    struct Day: Identifiable {
        let date: Date
        let steps: Int
        var id: Date { date }
    }

    @Published private(set) var snapshot: WatchSnapshot
    @Published private(set) var todaySteps = 0
    /// Last 7 days, oldest first, today last.
    @Published private(set) var week: [Day] = []

    private let healthStore = HKHealthStore()

    var state: AvatarState { AvatarLogic.determineState(steps: todaySteps) }
    var progress: Double { snapshot.goalProgress(steps: todaySteps) }

    override init() {
        // Last known values first, so the screen isn't empty before the phone checks in.
        if WatchLaunch.demoData {
            self.snapshot = WatchLaunch.Demo.snapshot
        } else if let snapshot = WatchSharedStore.load() {
            self.snapshot = snapshot
        } else {
            self.snapshot = .placeholder
        }
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - HealthKit

    func requestAuthorization() async {
        guard !WatchLaunch.demoData, HKHealthStore.isHealthDataAvailable() else { return }
        let steps = HKQuantityType(.stepCount)
        try? await healthStore.requestAuthorization(toShare: [], read: [steps])
    }

    /// Today's total and the last 7 days, in one collection query.
    func refresh() async {
        let calendar = Calendar.current
        if WatchLaunch.demoData {
            let today = calendar.startOfDay(for: Date())
            week = WatchLaunch.Demo.week.enumerated().compactMap { index, steps in
                calendar.date(byAdding: .day, value: index - 6, to: today).map { Day(date: $0, steps: steps) }
            }
            todaySteps = WatchLaunch.Demo.todaySteps
            return
        }
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let now = Date()
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -6, to: today) else { return }

        let predicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(.stepCount),
            predicate: HKQuery.predicateForSamples(withStart: start, end: nil)
        )
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: DateComponents(day: 1)
        )
        guard let collection = try? await descriptor.result(for: healthStore) else { return }

        var days: [Day] = []
        collection.enumerateStatistics(from: start, to: now) { statistics, _ in
            let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
            days.append(Day(date: calendar.startOfDay(for: statistics.startDate), steps: Int(steps)))
        }
        week = days
        let steps = days.last(where: { calendar.isDate($0.date, inSameDayAs: today) })?.steps ?? 0
        if steps != todaySteps {
            todaySteps = steps
            WidgetCenter.shared.reloadAllTimelines()   // keep complications in step with the app
        }
    }

    // MARK: - Snapshot from the iPhone

    fileprivate func apply(_ context: [String: Any]) {
        guard let snapshot = WatchSnapshot(dictionary: context) else { return }
        self.snapshot = snapshot
        WatchSharedStore.save(context)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension WatchStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return }
        Task { @MainActor in self.apply(context) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.apply(context) }
    }
}
