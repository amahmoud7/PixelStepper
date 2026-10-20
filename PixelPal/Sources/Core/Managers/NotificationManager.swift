import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    /// Requests notification permission. Returns true if granted.
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("NotificationManager: Permission error: \(error)")
            return false
        }
    }

    /// Checks current authorization status.
    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Daily Reminders

    /// Identifiers from the old repeating schedule; cleared on upgraded devices.
    private let legacyIdentifiers = ["daily_morning", "daily_evening", "mission_reminder", "weekly_summary", "streak_at_risk", "step_moment", "reengagement"]

    /// Last inputs the schedule was built from, so step-count ticks don't reschedule every time.
    private var lastPlanKey: String?
    private var goalMetToday = false
    private var streak = 0
    /// Rebuilds run one after another, so an older plan can't land after a newer one.
    private var scheduleTask: Task<Void, Never>?

    /// Rebuilds the week of reminders (after permission, and on every foreground).
    func scheduleAll() {
        lastPlanKey = nil
        reschedule()
    }

    func refreshSchedule() {
        scheduleAll()
    }

    /// Call when today's progress changes; only reschedules when the outcome would differ.
    func update(goalMetToday: Bool, streak: Int) {
        self.goalMetToday = goalMetToday
        self.streak = streak
        reschedule()
    }

    private func reschedule() {
        let now = Date()
        let day = Calendar.current.startOfDay(for: now)
        let key = "\(day.timeIntervalSince1970)|\(goalMetToday)|\(streak)"
        guard key != lastPlanKey else { return }
        lastPlanKey = key

        let plan = ReminderPlanner.plan(now: now, goalMetToday: goalMetToday, streak: streak)
        scheduleTask = Task { [previous = scheduleTask] in
            await previous?.value
            let pending = await center.pendingNotificationRequests()
            let stale = pending.map(\.identifier).filter { $0.hasPrefix(ReminderPlanner.idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale + legacyIdentifiers)
            for reminder in plan {
                let content = UNMutableNotificationContent()
                content.title = reminder.title
                content.body = reminder.body
                content.sound = .default
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                try? await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
            }
        }
    }
}
