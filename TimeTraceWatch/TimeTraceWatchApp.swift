import SwiftUI

@main
struct TimeTraceWatchApp: App {
    init() {
        WatchSyncStore.shared.activateAndRequestSync()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WatchSyncStore.shared)
        }
    }
}
