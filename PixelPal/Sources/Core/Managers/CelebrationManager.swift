import Foundation

/// Manages celebration triggers, queuing, and deduplication.
/// Each event shows at most once; several earned together are shown one after another.
@MainActor
class CelebrationManager: ObservableObject {
    /// Events waiting to be shown.
    private var queue: [CelebrationEvent] = []

    /// Events already shown this session.
    private var shownThisSession: Set<String> = []

    /// Attempts to trigger a celebration. Returns true if queued.
    @discardableResult
    func tryTrigger(_ event: CelebrationEvent) -> Bool {
        guard !shownThisSession.contains(event.id) else { return false }
        guard !queue.contains(where: { $0.id == event.id }) else { return false }

        queue.append(event)
        return true
    }

    /// Dequeues the next celebration to show.
    /// Returns nil when the queue is empty.
    func dequeueNext() -> CelebrationEvent? {
        guard !queue.isEmpty else { return nil }
        let event = queue.removeFirst()
        shownThisSession.insert(event.id)
        return event
    }
}
