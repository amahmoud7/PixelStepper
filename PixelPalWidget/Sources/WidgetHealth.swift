import Foundation
import HealthKit

/// Today's step count read directly by the widget, so it doesn't freeze at the last app launch.
/// Uses the app's existing Health permission. Returns nil when HealthKit can't answer
/// (device locked, permission denied, no data), and the widget then falls back to SharedData.
enum WidgetHealth {
    private static let store = HKHealthStore()

    static func todaySteps(now: Date = Date()) async -> Int? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(.stepCount),
            predicate: HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        )
        let descriptor = HKStatisticsQueryDescriptor(predicate: predicate, options: .cumulativeSum)
        do {
            let result = try await descriptor.result(for: store)
            return result.flatMap { $0.sumQuantity() }.map { Int($0.doubleValue(for: .count())) }
        } catch {
            return nil
        }
    }
}
