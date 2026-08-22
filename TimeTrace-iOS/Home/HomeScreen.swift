import SwiftUI
import SwiftData

// 这个文件是首页时间轴
struct HomeScreen: View {
    // 直接从数据库读数据，首页自动跟着变
    // 用 filter 分组天然实现置顶在前
    @Query(sort: [
        SortDescriptor(\DateEvent.position),
        SortDescriptor(\DateEvent.id, order: .reverse)
    ]) private var events: [DateEvent]
    @Environment(\.modelContext) private var modelContext

    @State private var pendingDelete: DateEvent?
    @State private var editingEvent: DateEvent?
    // 控制全屏编辑器是否弹出
    @State private var showAddEditor = false
    // 进详情页
    @State private var detailEvent: DateEvent?
    // 添加按钮弹跳计数
    @State private var addButtonBounce = 0

    @Environment(\.horizontalSizeClass) private var sizeClass
    // 判断留不留毛玻璃
    @Environment(\.colorScheme) private var colorScheme

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
            .background(TimeTracePalette.background.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                headerView
            }
            .alert("确认删除", isPresented: deleteAlertBinding, presenting: pendingDelete) { event in
                Button("删除", role: .destructive) { delete(event) }
                Button("取消", role: .cancel) {}
            } message: { event in
                Text("确定要删除\"\(event.title)\"吗？此操作不可撤销。")
            }
            .sheet(item: $editingEvent) { item in
                EditEventSheet(
                    event: item,
                    onSave: { editingEvent = nil },
                    onCancel: { editingEvent = nil }
                )
            }
            // 新增记录走全屏编辑器
            .fullScreenCover(isPresented: $showAddEditor) {
                EditorScreen(
                    onDismiss: { showAddEditor = false },
                    onSave: { event in
                        addNew(event)
                        showAddEditor = false
                    }
                )
            }
            // 点卡片进详情页
            .fullScreenCover(item: $detailEvent) { event in
                DetailScreen(events: events, initialEventId: event.id)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: pendingDelete?.id)
    }

    // 顶部标题栏双行品牌标题，添加按钮和它同一水平线
    private var headerView: some View {
        HStack(alignment: .center) {
            // 小字品牌上，大字标题在下
            VStack(alignment: .leading, spacing: 0) {
                Text("TimeTrace")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TimeTracePalette.secondary)
                    .offset(x: 1.5)
                Text("时间轴")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(TimeTracePalette.onSurface)
            }
            Spacer()
            // 添加按钮，26及以上用官方液态玻璃，老的系统退回普通毛玻璃
            Button(action: {
                addButtonBounce += 1
                showAddEditor = true
            }) {
                Group {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(TimeTracePalette.primary)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular, in: Circle())
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(TimeTracePalette.primary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .symbolEffect(.bounce, value: addButtonBounce)   // 点击弹跳
            }
            .accessibilityLabel("添加")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            // 顶部毛玻璃背景覆盖整个顶部，延伸到状态栏后面
            Rectangle()
                .fill(.regularMaterial)
                .overlay {
                    // 深色没毛玻璃，浅色模式保留
                    if colorScheme == .dark {
                        TimeTracePalette.background.opacity(1.0)
                    }
                }
                .ignoresSafeArea(edges: .top)
        }
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
        // 不要上下滚动时的滚动条
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 120, for: .scrollContent)
        // 整条列表往内缩，让滑出的按钮离屏幕左右边框留白
        .padding(.horizontal, 8)
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
        // 和 ‘.padding(.horizontal, 8)’ 对冲
        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        // 左滑编辑，右滑删除
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button { editingEvent = event } label: { Label("编辑", systemImage: "pencil") }
                .tint(TimeTracePalette.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                // 不用 destructive 角色，第一次点击只弹确认、不播删除动画；等滑动收起后再弹框
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    pendingDelete = event
                }
            } label: { Label("删除", systemImage: "trash") }
                .tint(.red)
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

    // 点卡片进全屏详情页捏
    private func open(_ event: DateEvent) {
        detailEvent = event
    }

    // 确认删除
    private func delete(_ event: DateEvent) {
        withAnimation {
            modelContext.delete(event)
            try? modelContext.save()
        }
        pendingDelete = nil
    }

    // 把编辑器新建的记录放进数据库
    private func addNew(_ event: DateEvent) {
        // 新记录还没有编号，先发一个
        if event.id == 0 {
            event.id = EventIDGenerator.next()
        }
        modelContext.insert(event)
        try? modelContext.save()
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
        .modelContainer(MockData.previewContainer())
}

#Preview("首页深色模式") {
    HomeScreen()
        .modelContainer(MockData.previewContainer())
        .preferredColorScheme(.dark)
}
