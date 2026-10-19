import Foundation

/// Snapshot cache shared by the watch app and its complications through an App Group.
/// The app writes what the iPhone sends; complications read it (they can't use WatchConnectivity).
enum WatchSharedStore {
    static let suiteName = "group.com.pixelpalfit.app.watch"
    private static let key = "watchSnapshot"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func load() -> WatchSnapshot? {
        defaults.dictionary(forKey: key).flatMap(WatchSnapshot.init(dictionary:))
    }

    static func save(_ context: [String: Any]) {
        defaults.set(context, forKey: key)
    }
}
