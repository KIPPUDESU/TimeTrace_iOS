import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WatchSyncStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.events.isEmpty {
                WatchEmptyView()
            } else {
                TabView {
                    ForEach(store.events) { event in
                        WatchPosterView(
                            event: event,
                            backgroundRevision: store.backgroundRevision
                        )
                    }
                }
                .tabViewStyle(.verticalPage)
                .ignoresSafeArea()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            store.activateAndRequestSync()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.activateAndRequestSync()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSyncStore.shared)
}
