import Foundation
import UserNotifications

/// Schedules random daily Step Moment notification and stores today's moment.
@MainActor
class StepMomentManager: ObservableObject {
    @Published var todayMoment: StepMoment?
    @Published var hasCheckedToday: Bool = false

    private let center = UNUserNotificationCenter.current()

    private var todayString: String {
        DailyGoalState.dayKey(for: Date())
    }

    init() {
        loadTodayMoment()
    }

    // MARK: - Schedule

    /// Schedules tomorrow's Step Moment notification at a random time (10am-8pm).
    func scheduleNextMoment() {
        center.removePendingNotificationRequests(withIdentifiers: ["step_moment"])

        let content = UNMutableNotificationContent()
        content.title = "Step Moment!"
        content.body = "How's your day going? Check in now."
        content.sound = .default
        content.categoryIdentifier = "STEP_MOMENT"

        // Random hour between 10-20 (10am-8pm), deterministic from date
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var rng = SeededRandomNumberGenerator(string: DailyGoalState.dayKey(for: tomorrow))
        let hour = Int.random(in: 10...19, using: &rng)
        let minute = Int.random(in: 0...59, using: &rng)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "step_moment", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Capture

    /// Captures today's Step Moment.
    func captureMoment(steps: Int, state: String, phase: Int) {
        let moment = StepMoment.capture(steps: steps, state: state, phase: phase)
        todayMoment = moment
        hasCheckedToday = true
        saveMoment(moment)
        scheduleNextMoment()
    }

    // MARK: - Persistence

    private func loadTodayMoment() {
        guard let data = try? Data(contentsOf: momentFileURL),
              let moment = try? JSONDecoder().decode(StepMoment.self, from: data) else { return }

        if moment.dateString == todayString {
            todayMoment = moment
            hasCheckedToday = true
        }
    }

    private func saveMoment(_ moment: StepMoment) {
        guard let data = try? JSONEncoder().encode(moment) else { return }
        try? data.write(to: momentFileURL, options: .atomic)
    }

    private var momentFileURL: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = (urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("PixelPal", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("StepMoment.json")
    }
}
