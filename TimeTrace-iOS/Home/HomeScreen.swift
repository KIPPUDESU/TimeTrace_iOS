import SwiftUI

// 这个文件是首页时间轴
struct HomeScreen: View {
    @State private var events: [DateEvent]
    @State private var pendingDelete: DateEvent?
    @State private var editingEvent: DateEvent?

    @Environment(\.horizontalSizeClass) private var sizeClass

    init(events: [DateEvent] = MockData.sampleEvents) {
        self._events = State(initialValue: events)
    }

    // 置顶单独一组
    private var pinnedEvents: [DateEvent] { events.filter(\.isPinned) }
    // 没置顶另一组
    private var normalEvents: [DateEvent] { events.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack {
            Group {
                // 没有记录时显示提示，平板双列网格，手机单列列表
                if events.isEmpty {
                    emptyState
                } else if sizeClass == .regular {
                    gridLayout
                } else {
                    listLayout
                }
            }
            .background(TimeTracePalette.background)
            .navigationTitle("时间轴")
            .toolbar {
                // 右上角的加号按钮，是液态玻璃来着，用来新建记录
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addEvent) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加")
                }
            }
            .alert("确认删除", isPresented: deleteAlertBinding, presenting: pendingDelete) { event in
                Button("删除", role: .destructive) { delete(event) }
                Button("取消", role: .cancel) {}
            } message: { event in
                Text("确定要删除\"\(event.title)\"吗？此操作不可撤销。")
            }
            .sheet(item: $editingEvent) { item in
                EditEventSheet(
                    event: Binding(get: { item }, set: { editingEvent = $0 }),
                    onSave: { update($0) },
                    onCancel: { editingEvent = nil }
                )
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: pendingDelete?.id)
    }

    // 手机上用的单列列表
    private var listLayout: some View {
        List {
            ForEach(pinnedEvents) { event in
                cardRow(event: event, isPinned: true)
            }
            ForEach(normalEvents) { event in
                cardRow(event: event, isPinned: false)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 120, for: .scrollContent)
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
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        // 左滑编辑，右滑删除
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button { editingEvent = event } label: { Label("编辑", systemImage: "pencil") }
                .tint(TimeTracePalette.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { pendingDelete = event } label: { Label("删除", systemImage: "trash") }
        }
    }

    // 平板上用的双列网格
    private var gridLayout: some View {
        let all = pinnedEvents + normalEvents
        return ScrollView {
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
        .scrollIndicators(.hidden)
    }

    // 没有记录的提示
    private var emptyState: some View {
        Text("点击右上角 + 记录你的 TimeTrace")
            .font(.body)
            .foregroundStyle(TimeTracePalette.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 点卡片先打开编辑面板，暂时先这样捏
    private func open(_ event: DateEvent) {
        editingEvent = event
    }

    // 新建记录，编辑器做好之前先用空事件打开编辑面板
    private func addEvent() {
        editingEvent = DateEvent(title: "", targetDate: Date(), isFuture: true, mode: .countDown)
    }

    // 确认删除
    private func delete(_ event: DateEvent) {
        withAnimation {
            events.removeAll { $0.id == event.id }
        }
        pendingDelete = nil
    }

    // 把编辑后的结果存回列表，是新记录就加进去
    private func update(_ event: DateEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        editingEvent = nil
    }

    // 判断删除确认框
    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }
}

// 预览用的两种模式
#Preview("首页浅色模式") {
    HomeScreen()
}

#Preview("首页深色模式") {
    HomeScreen()
        .preferredColorScheme(.dark)
}
