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
    @State private var showStoppedDrawer = false
    @State private var livePullDistance: CGFloat = 0
    @State private var emptyPullDistance: CGFloat = 0

    @Environment(\.horizontalSizeClass) private var sizeClass
    // 判断留不留毛玻璃
    @Environment(\.colorScheme) private var colorScheme
    // 在卡片之间的缝上横滑时穿参
    var onGapSwipe: ((_ toNext: Bool) -> Void)? = nil
    // 内容要滑动距离
    @Environment(\.tabSlideOffset) private var slideOffset
    // 内容淡入用，背景不跟着淡
    @Environment(\.tabReveal) private var reveal

    private var activeEvents: [DateEvent] { events.filter { !$0.isStopped } }
    // 置顶单独一组
    private var pinnedEvents: [DateEvent] { activeEvents.filter(\.isPinned) }
    // 没置顶另一组
    private var normalEvents: [DateEvent] { activeEvents.filter { !$0.isPinned } }
    // 屏幕上从上到下的真实顺序
    private var orderedEvents: [DateEvent] { pinnedEvents + normalEvents }
    // 顶部遮罩高度
    private let headerTotal: CGFloat = 118
    private let stoppedDrawerPullThreshold: CGFloat = 220
    private let pullHintRevealStart: CGFloat = 72

    private var effectivePullDistance: CGFloat {
        max(livePullDistance, emptyPullDistance)
    }

    private var pullHintProgress: CGFloat {
        let span = stoppedDrawerPullThreshold - pullHintRevealStart
        guard span > 0, effectivePullDistance > pullHintRevealStart else { return 0 }
        return min(1, (effectivePullDistance - pullHintRevealStart) / span)
    }

    private var isPullReadyToOpen: Bool { pullHintProgress >= 0.98 }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // 底色放在导航栈内部最底
                TimeTracePalette.background.ignoresSafeArea()

                // 卡片内容层
                Group {
                    // 没有记录时显示提示，平板双列网格，手机单列列表
                    if activeEvents.isEmpty {
                        emptyState
                            .gesture(emptyPullGesture)
                    } else if sizeClass == .regular {
                        gridLayout
                    } else {
                        listLayout
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)
                // 左右渐隐
                .overlay(alignment: .leading) { edgeFade(solidOnLeading: true) }
                .overlay(alignment: .trailing) { edgeFade(solidOnLeading: false) }
                .offset(x: slideOffset)
                .opacity(reveal)

                // 顶部材质遮罩钉住
                headerMaterialBar

                headerTitleRow
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .offset(x: slideOffset)
                    .opacity(reveal)

                if pullHintProgress > 0 {
                    pullToDrawerHint
                        .offset(x: slideOffset)
                        .allowsHitTesting(false)
                }
            }
            .alert(L("confirm_delete_title"), isPresented: deleteAlertBinding, presenting: pendingDelete) { event in
                Button(L("delete_button"), role: .destructive) { delete(event) }
                Button(L("cancel"), role: .cancel) {}
            } message: { event in
                Text(String(format: L("delete_confirm_message"), event.title))
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
                DetailScreen(events: orderedEvents, initialEventId: event.id)
            }
            .fullScreenCover(isPresented: $showStoppedDrawer) {
                StoppedDrawerScreen()
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: pendingDelete?.id)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPullReadyToOpen)
    }

    private var pullToDrawerHint: some View {
        let progress = pullHintProgress
        let ready = isPullReadyToOpen
        return VStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(TimeTracePalette.secondary.opacity(0.22), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: max(0.04, progress))
                    .stroke(
                        TimeTracePalette.secondary.opacity(0.9),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TimeTracePalette.secondary)
                    .rotationEffect(.degrees(ready ? 180 : 0))
            }
            .frame(width: 26, height: 26)
            .animation(.easeInOut(duration: 0.18), value: ready)

            Text(L("pull_to_stopped_hint"))
                .font(.caption2)
                .foregroundStyle(TimeTracePalette.secondary)
                .opacity(0.55 + 0.45 * Double(progress))
        }
        .opacity(Double(min(1, progress * 1.15)))
        .offset(y: headerTotal - 6 + min(effectivePullDistance * 0.35, 64))
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var emptyPullGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let dy = value.translation.height
                guard dy > 0, abs(dy) > abs(value.translation.width) else {
                    emptyPullDistance = 0
                    return
                }
                emptyPullDistance = dy
            }
            .onEnded { _ in
                if emptyPullDistance >= stoppedDrawerPullThreshold {
                    showStoppedDrawer = true
                }
                emptyPullDistance = 0
            }
    }

    private func trackPullDistance(_ distance: CGFloat) {
        livePullDistance = distance
    }

    // 抬起瞬间判定；idle 时橡皮筋已回弹，距离不可用
    private func handlePullScrollPhase(from oldPhase: ScrollPhase, to newPhase: ScrollPhase) {
        if oldPhase == .interacting && newPhase != .interacting {
            if livePullDistance >= stoppedDrawerPullThreshold {
                showStoppedDrawer = true
            }
        }
        if newPhase == .idle {
            livePullDistance = 0
        }
    }

    private func overscrollPullDistance(from geometry: ScrollGeometry) -> CGFloat {
        max(0, -(geometry.contentOffset.y + geometry.contentInsets.top))
    }

    // 缝柔化
    private func edgeFade(solidOnLeading: Bool) -> some View {
        LinearGradient(
            stops: [
                .init(color: TimeTracePalette.background, location: 0),
                .init(color: TimeTracePalette.background, location: 0.8),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 16)
        .scaleEffect(x: solidOnLeading ? 1 : -1, y: 1)
        .blur(radius: 2)
        .allowsHitTesting(false)
    }

    private var headerMaterialBar: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                // 深色没毛玻璃，浅色模式保留
                if colorScheme == .dark {
                    TimeTracePalette.background.opacity(1.0)
                }
            }
            .frame(height: headerTotal)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    // 小字品牌 大字标题 添加按钮
    private var headerTitleRow: some View {
        HStack(alignment: .center) {
            // 小字品牌上，大字标题在下
            VStack(alignment: .leading, spacing: 0) {
                Text("TimeTrace")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TimeTracePalette.secondary)
                    .offset(x: 1.5)
                Text(L("timeline_title"))
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
            .accessibilityLabel("add")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    // 手机上用的单列列表
    private var listLayout: some View {
        List {
            // 也挺好
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
        // 不要上下滚动时的滚动条
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 120, for: .scrollContent)
        // 整条列表往内缩，让滑出的按钮离屏幕左右边框留白
        .padding(.horizontal, 8)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            overscrollPullDistance(from: geometry)
        } action: { _, distance in
            trackPullDistance(distance)
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            handlePullScrollPhase(from: oldPhase, to: newPhase)
        }
    }

    // 透明横滑带 因为苹果你 list 真紧吧 我只能这么妥协了 还不知道手指滑动是什么样呢
    private var gapSwipeBand: some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(height: 8)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > 20, abs(dx) > abs(dy) * 1.3 else { return }
                        onGapSwipe?(dx < 0)
                    }
            )
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
        .overlay(alignment: .top) { gapSwipeBand.offset(y: -8) }
        .overlay(alignment: .bottom) { gapSwipeBand.offset(y: 8) }
        // 只放图标
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button { editingEvent = event } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 2, weight: .medium))
                    .accessibilityLabel(L("edit_title"))
            }
            .tint(TimeTracePalette.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                // 不用 destructive 角色，第一次点击只弹确认、不播删除动画；等滑动收起后再弹框
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

    // 平板上用的双列网格
    private var gridLayout: some View {
        let all = orderedEvents
        return ScrollView {
            VStack(spacing: 0) {
                // 空白垫出遮罩高度
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
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            overscrollPullDistance(from: geometry)
        } action: { _, distance in
            trackPullDistance(distance)
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            handlePullScrollPhase(from: oldPhase, to: newPhase)
        }
    }

    // 没有记录的提示
    private var emptyState: some View {
        Text(L("empty_timeline_hint"))
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
        .modelContainer(PresetData.previewContainer())
}

#Preview("首页深色模式") {
    HomeScreen()
        .modelContainer(PresetData.previewContainer())
        .preferredColorScheme(.dark)
}
