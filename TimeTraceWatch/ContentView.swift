import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WatchSyncStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var showStoppedDrawer = false
    @State private var swipeDistance: CGFloat = 0

    private let swipeThreshold: CGFloat = 56
    private let swipeHintStart: CGFloat = 14

    private var activeEvents: [WatchSyncEvent] { store.activeEvents }

    private var swipeProgress: CGFloat {
        guard swipeDistance > swipeHintStart else { return 0 }
        return min(1, (swipeDistance - swipeHintStart) / max(swipeThreshold - swipeHintStart, 1))
    }

    var body: some View {
        Group {
            if store.events.isEmpty {
                WatchEmptyView()
            } else if activeEvents.isEmpty {
                activeEmptyPlaceholder
            } else {
                TabView {
                    ForEach(activeEvents) { event in
                        eventPage(event)
                    }
                }
                .tabViewStyle(.verticalPage)
                .ignoresSafeArea()
            }
        }
        .simultaneousGesture(swipeFromLeftGesture)
        .overlay(alignment: .leading) {
            if swipeProgress > 0 {
                swipeHint
                    .allowsHitTesting(false)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showStoppedDrawer) {
            WatchStoppedDrawerView()
                .environmentObject(store)
        }
        .onAppear {
            store.activateAndRequestSync()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.activateAndRequestSync()
            }
        }
    }

    @ViewBuilder
    private func eventPage(_ event: WatchSyncEvent) -> some View {
        if store.isBackgroundReady(for: event) {
            WatchPosterView(
                event: event,
                backgroundRevision: store.backgroundRevision
            )
        } else {
            WatchIncompleteEventView()
        }
    }

    private var activeEmptyPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.secondary)
            Text(WL("swipe_to_stopped_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var swipeHint: some View {
        let ready = swipeProgress >= 0.98
        return GlassEffectContainer {
            VStack(spacing: 5) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(ready ? WL("release_to_stopped_hint") : WL("swipe_to_stopped_hint"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .padding(.leading, 6)
        .opacity(Double(min(1, 0.4 + swipeProgress * 0.8)))
        .offset(x: min(swipeDistance * 0.2, 18))
    }

    private var swipeFromLeftGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                // 从左向右，且明显偏横向
                guard dx > 0, abs(dx) > abs(dy) * 1.25 else {
                    swipeDistance = 0
                    return
                }
                swipeDistance = dx
            }
            .onEnded { _ in
                defer { swipeDistance = 0 }
                guard swipeDistance >= swipeThreshold else { return }
                showStoppedDrawer = true
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSyncStore.shared)
}
