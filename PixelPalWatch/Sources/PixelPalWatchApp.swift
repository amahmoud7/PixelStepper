import SwiftUI

@main
struct PixelPalWatchApp: App {
    @StateObject private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                TodayView()
                StreakView()
            }
            .tabViewStyle(.page)
            .environmentObject(store)
            .task {
                await store.requestAuthorization()
                // Refresh while the app is on screen; the task is cancelled when it isn't.
                while !Task.isCancelled {
                    await store.refresh()
                    try? await Task.sleep(nanoseconds: 60_000_000_000)
                }
            }
        }
    }
}
