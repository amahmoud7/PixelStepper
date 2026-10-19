import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    /// Today's step count (for display).
    @Published var currentSteps: Double = 0

    /// Per-day step counts for the last 7 days, keyed by start-of-day Date.
    @Published var dailyStepsLast7Days: [Date: Int] = [:]

    /// Steps between midnight and noon today (for the morning mission). Nil until known.
    @Published var stepsBeforeNoon: Int?

    /// Steps since 17:00 today (for the evening mission). Nil before 17:00 or until known.
    @Published var stepsSinceFivePM: Int?

    /// Cumulative steps (all history up to now).
    @Published var cumulativeSteps: Int = 0

    /// Whether HealthKit authorization has been requested (not whether granted —
    /// Apple doesn't expose read permission status for privacy).
    @Published var isAuthorized: Bool = false

    /// Whether HealthKit is available on this device.
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Last sync timestamp (not published: no view reads it, and publishing re-renders the tree).
    private(set) var lastSync: Date?

    /// Steps before today, cached per day. Cumulative = this + today's live count,
    /// so the expensive multi-year sum runs once a day instead of on every foreground.
    private var priorDaysCache: (dayStart: Date, steps: Int)?

    /// Throttles duplicate fetches fired by launch/foreground/authorization in quick succession.
    private var lastFetch = Date.distantPast
    private let fetchThrottle: TimeInterval = 5

    private var stepType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .stepCount)!
    }

    /// Requests HealthKit authorization and fetches data.
    /// Safe to call on every app launch — idempotent if already granted.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [stepType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                // Note: For read-only permissions, success=true even if user denied.
                // This is Apple's privacy-by-design — we can't detect read denial.
                self.isAuthorized = success
                // Always try to fetch data — if denied, queries return 0 silently.
                self.fetchData(force: true)
                completion(success)
            }
        }
    }

    /// Fetches today's steps and the last 7 days. Calls within a few seconds of each other are coalesced.
    func fetchData(force: Bool = false) {
        guard force || Date().timeIntervalSince(lastFetch) > fetchThrottle else { return }
        lastFetch = Date()
        fetchTodaySteps()
        fetchDailyStepsLast7Days()
        fetchMissionWindows()
    }

    /// Morning (00:00–12:00) and evening (17:00–now) totals, so missions count real windows.
    private func fetchMissionWindows() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        guard let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now),
              let fivePM = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) else { return }

        querySum(from: startOfDay, to: min(now, noon)) { [weak self] steps in
            guard let self, self.stepsBeforeNoon != steps else { return }
            self.stepsBeforeNoon = steps
        }
        if now >= fivePM {
            querySum(from: fivePM, to: now) { [weak self] steps in
                guard let self, self.stepsSinceFivePM != steps else { return }
                self.stepsSinceFivePM = steps
            }
        } else if stepsSinceFivePM != nil {
            stepsSinceFivePM = nil
        }
    }

    /// Step total in [start, end); completion runs on the main queue with nil on failure.
    private func querySum(from start: Date, to end: Date, completion: @escaping (Int?) -> Void) {
        guard start < end else {
            completion(0)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            let steps: Int? = HealthKitManager.isUsable(error)
                ? Int(result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)
                : nil
            DispatchQueue.main.async { completion(steps) }
        }
        healthStore.execute(query)
    }

    private func fetchTodaySteps() {
        queryTodaySteps { _ in }
    }

    /// Awaitable today-only refresh (pull-to-refresh), so the spinner tracks the real query.
    @MainActor
    func refreshToday() async {
        lastFetch = Date()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queryTodaySteps { _ in continuation.resume() }
        }
    }

    /// Runs today's step sum and applies it on the main queue, then calls `completion` there.
    private func queryTodaySteps(completion: @escaping (Bool) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            // "No data" (no samples yet today) is a real zero, not a failure — otherwise
            // yesterday's count would carry past midnight.
            guard HealthKitManager.isUsable(error) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                guard let self else { return completion(false) }
                self.lastSync = Date()
                if self.currentSteps != steps {
                    self.currentSteps = steps
                }
                if let cache = self.priorDaysCache, cache.dayStart == startOfDay {
                    self.setCumulative(cache.steps + Int(steps))
                }
                completion(true)
            }
        }
        healthStore.execute(query)
    }

    /// True when a statistics query succeeded or merely found no samples.
    private static func isUsable(_ error: Error?) -> Bool {
        guard let error else { return true }
        return (error as? HKError)?.code == .errorNoData
    }

    /// Fetches per-day step totals for the last 7 days using HKStatisticsCollectionQuery.
    private func fetchDailyStepsLast7Days() {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: sevenDaysAgo,
            intervalComponents: DateComponents(day: 1)
        )

        query.initialResultsHandler = { [weak self] _, results, error in
            if let error = error {
                print("HealthKitManager: Failed to fetch daily steps: \(error)")
                return
            }
            guard let results = results else { return }

            var dailyMap: [Date: Int] = [:]
            results.enumerateStatistics(from: sevenDaysAgo, to: now) { statistics, _ in
                let day = calendar.startOfDay(for: statistics.startDate)
                let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                dailyMap[day] = Int(steps)
            }

            DispatchQueue.main.async {
                guard let self, self.dailyStepsLast7Days != dailyMap else { return }
                self.dailyStepsLast7Days = dailyMap
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Cumulative Step Tracking

    /// Total steps since `baselineDate`: a per-day cached sum of prior days plus today's live count.
    @MainActor
    func fetchCumulativeStepsAsync(since baselineDate: Date) async -> Int {
        let startOfToday = Calendar.current.startOfDay(for: Date())

        if let cache = priorDaysCache, cache.dayStart == startOfToday {
            let total = cache.steps + Int(currentSteps)
            setCumulative(total)
            return total
        }

        guard baselineDate < startOfToday else { return Int(currentSteps) }
        let predicate = HKQuery.predicateForSamples(withStart: baselineDate, end: startOfToday, options: .strictStartDate)
        let type = stepType

        let prior: Int? = await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                // Don't cache real failures (e.g. protected data while locked); retry next time.
                guard HealthKitManager.isUsable(error) else {
                    continuation.resume(returning: nil)
                    return
                }
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }

        guard let prior else { return Int(currentSteps) }
        priorDaysCache = (startOfToday, prior)
        let total = prior + Int(currentSteps)
        setCumulative(total)
        return total
    }

    /// Invalidates the cumulative cache (call when user pulls to refresh).
    func invalidateCache() {
        priorDaysCache = nil
        lastFetch = .distantPast
    }

    private func setCumulative(_ total: Int) {
        if cumulativeSteps != total {
            cumulativeSteps = total
        }
    }
}
