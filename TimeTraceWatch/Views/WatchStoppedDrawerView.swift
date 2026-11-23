import SwiftUI

struct WatchStoppedDrawerView: View {
    @EnvironmentObject private var store: WatchSyncStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if store.stoppedEvents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "pause.circle")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text(WL("stopped_empty"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView {
                    ForEach(store.stoppedEvents) { event in
                        Group {
                            if store.isBackgroundReady(for: event) {
                                WatchPosterView(
                                    event: event,
                                    backgroundRevision: store.backgroundRevision
                                )
                            } else {
                                WatchIncompleteEventView()
                            }
                        }
                    }
                }
                .tabViewStyle(.verticalPage)
                .ignoresSafeArea()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .accessibilityLabel(WL("close"))
            }
        }
    }
}

#Preview {
    WatchStoppedDrawerView()
        .environmentObject(WatchSyncStore.shared)
}
