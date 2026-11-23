import SwiftUI
import SwiftData

struct StoppedDrawerScreen: View {
    @Query(sort: [
        SortDescriptor(\DateEvent.position),
        SortDescriptor(\DateEvent.id, order: .reverse)
    ]) private var events: [DateEvent]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme

    @State private var pendingDelete: DateEvent?
    @State private var pendingRestore: DateEvent?
    @State private var detailEvent: DateEvent?

    private var stoppedEvents: [DateEvent] { events.filter(\.isStopped) }
    private var pinnedEvents: [DateEvent] { stoppedEvents.filter(\.isPinned) }
    private var normalEvents: [DateEvent] { stoppedEvents.filter { !$0.isPinned } }
    private var orderedEvents: [DateEvent] { pinnedEvents + normalEvents }
    private let headerTotal: CGFloat = 118

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                TimeTracePalette.background.ignoresSafeArea()

                Group {
                    if stoppedEvents.isEmpty {
                        emptyState
                    } else if sizeClass == .regular {
                        gridLayout
                    } else {
                        listLayout
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)

                headerMaterialBar
                headerTitleRow
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .alert(L("confirm_delete_title"), isPresented: deleteAlertBinding, presenting: pendingDelete) { event in
                Button(L("delete_button"), role: .destructive) { delete(event) }
                Button(L("cancel"), role: .cancel) {}
            } message: { event in
                Text(String(format: L("delete_confirm_message"), event.title))
            }
            .alert(L("confirm_restore_title"), isPresented: restoreAlertBinding, presenting: pendingRestore) { event in
                Button(L("restore_button")) { restore(event) }
                Button(L("cancel"), role: .cancel) {}
            } message: { event in
                Text(String(format: L("restore_confirm_message"), event.title))
            }
            .fullScreenCover(item: $detailEvent) { event in
                DetailScreen(events: orderedEvents, initialEventId: event.id)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: pendingDelete?.id)
    }

    private var headerMaterialBar: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                if colorScheme == .dark {
                    TimeTracePalette.background.opacity(1.0)
                }
            }
            .frame(height: headerTotal)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    private var headerTitleRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("TimeTrace")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TimeTracePalette.secondary)
                    .offset(x: 1.5)
                Text(L("stopped_drawer_title"))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(TimeTracePalette.onSurface)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Group {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(TimeTracePalette.primary)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular, in: Circle())
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(TimeTracePalette.primary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .accessibilityLabel(L("close"))
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    private var listLayout: some View {
        List {
            Color.clear
                .frame(height: headerTotal)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            ForEach(pinnedEvents) { event in
                cardRow(event: event, isPinned: true)
            }
            ForEach(normalEvents) { event in
                cardRow(event: event, isPinned: false)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 120, for: .scrollContent)
        .padding(.horizontal, 8)
    }

    private var gridLayout: some View {
        let all = orderedEvents
        return ScrollView {
            VStack(spacing: 0) {
                Color.clear.frame(height: headerTotal)
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 300), spacing: 12)],
                    spacing: 16
                ) {
                    ForEach(all) { event in
                        if event.isPinned {
                            PinnedEventCard(event: event) { open(event) }
                        } else {
                            NormalEventCard(event: event) { open(event) }
                        }
                    }
                }
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 120, trailing: 16))
            }
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        Text(L("stopped_empty"))
            .font(.body)
            .foregroundStyle(TimeTracePalette.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, headerTotal)
    }

    @ViewBuilder
    private func cardRow(event: DateEvent, isPinned: Bool) -> some View {
        Group {
            if isPinned {
                PinnedEventCard(event: event) { open(event) }
            } else {
                NormalEventCard(event: event) { open(event) }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    pendingRestore = event
                }
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 2, weight: .medium))
                    .accessibilityLabel(L("restore_button"))
            }
            .tint(TimeTracePalette.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    pendingDelete = event
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 2, weight: .medium))
                    .accessibilityLabel(L("delete_button"))
            }
            .tint(.red)
        }
    }

    private func open(_ event: DateEvent) {
        detailEvent = event
    }

    private func delete(_ event: DateEvent) {
        withAnimation {
            modelContext.delete(event)
            try? modelContext.save()
        }
        pendingDelete = nil
    }

    private func restore(_ event: DateEvent) {
        withAnimation {
            event.stoppedAt = nil
            try? modelContext.save()
        }
        pendingRestore = nil
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private var restoreAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingRestore != nil },
            set: { if !$0 { pendingRestore = nil } }
        )
    }
}

#Preview("已定格抽屉") {
    StoppedDrawerScreen()
        .modelContainer(PresetData.previewContainer())
}
