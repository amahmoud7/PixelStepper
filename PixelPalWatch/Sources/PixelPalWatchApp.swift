import SwiftUI

@main
struct PixelPalWatchApp: App {
    @StateObject private var store = WatchStore()
    @State private var page = WatchLaunch.startPage

    var body: some Scene {
        WindowGroup {
            TabView(selection: $page) {
                TodayView().tag(0)
                StreakView().tag(1)
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
