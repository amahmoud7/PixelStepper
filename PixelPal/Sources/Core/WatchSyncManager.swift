import Foundation
import WatchConnectivity

/// Sends the character, phase and streak to the Apple Watch app.
/// Uses the application context: the system keeps only the latest one and delivers it
/// whenever the watch app next runs, so there's no queue to manage.
@MainActor
final class WatchSyncManager: NSObject {
    static let shared = WatchSyncManager()

    private var lastSent: WatchSnapshot?
    private var pending: WatchSnapshot?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Call whenever anything the watch shows may have changed. Duplicate snapshots are ignored.
    func send(_ snapshot: WatchSnapshot) {
        guard WCSession.isSupported() else { return }
        // Ignore the timestamp when deciding whether anything changed.
        var comparable = snapshot
        comparable.updatedAt = lastSent?.updatedAt ?? snapshot.updatedAt
        guard comparable != lastSent else { return }

        let session = WCSession.default
        guard session.activationState == .activated else {
            pending = snapshot
            return
        }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        do {
            try session.updateApplicationContext(snapshot.dictionary)
            lastSent = snapshot
        } catch {
            print("WatchSyncManager: Failed to update context: \(error)")
        }
    }
}

extension WatchSyncManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if state == .activated, let pending = self.pending {
                self.pending = nil
                self.send(pending)
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Switching watches: reactivate for the new one.
        WCSession.default.activate()
    }
}
