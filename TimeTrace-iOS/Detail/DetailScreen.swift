import SwiftUI
import Photos
import PhotosUI
import UIKit

// 全屏详情页
struct DetailScreen: View {
    let events: [DateEvent]
    let initialEventId: Int64
    // 返回按钮要做什么。当成标签页用时没有弹层可关，得由外面告诉它回哪去
    var onBack: (() -> Void)? = nil
    // 亲爱的用户在详情标 tab 又点了一下
    var reselectTick: Int = 0

    @Environment(\.dismiss) private var dismiss
    // 标签切换时整页会横移，垫底的黑靠它把自己挪回原位
    @Environment(\.tabSlideOffset) private var slideOffset
    // 渲染保存图片用的显示缩放
    @Environment(\.displayScale) private var displayScale

    // 控制栏是否显示
    @State private var showControls = false
    // 几何算出的当前页
    @State private var currentPage: Int = 0
    // 滚动几何实时算出的页码，等停稳后再提交
    @State private var computedPage: Int = 0
    // 屏幕尺寸，保存图片渲染用
    @State private var screenSize: CGSize = .zero
    // 起始页虚拟页中对应被点事件的页
    private let startPage: Int
    // 底部动作
    @State private var showActionSheet = false
    // 保存成功横幅
    @State private var showSavedBanner = false

    // 编辑相关状态
    @State private var showTitleEdit = false
    @State private var draftTitle = ""
    @State private var showDatePicker = false
    @State private var showPhotoPicker = false
    @State private var pickerItem: PhotosPickerItem?

    // 依旧和安卓一样，直接给几百万页，起始页对齐到初始事件
    private static let virtualCount = 1_000_000
    // 我们 现在 就 靠这个 键 找回 了 ！
    private static let resumeKey = "DetailScreen.scrollVirtual"

    init(events: [DateEvent], initialEventId: Int64, onBack: (() -> Void)? = nil, reselectTick: Int = 0) {
        self.events = events
        self.initialEventId = initialEventId
        self.onBack = onBack
        self.reselectTick = reselectTick
        let idx = events.firstIndex(where: { $0.id == initialEventId }) ?? 0
        let half = Self.virtualCount / 2
        let n = events.count
        var computed = n > 1 ? half - (half % n) + idx : 0
        // 作为标签页用（有返回动作）时重建后靠这里回到上次停的位置，天数照常播动画
        if onBack != nil, n > 1,
           let saved = UserDefaults.standard.object(forKey: Self.resumeKey) as? Int,
           saved >= 0, saved < Self.virtualCount {
            computed = saved
        }
        self.startPage = computed
        // computedPage 初值也对齐，不要让首次 idle 提交把当前页错位成 0
        _currentPage = State(initialValue: computed)
        _computedPage = State(initialValue: computed)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if events.isEmpty {
                emptyState
            } else {
                pager
            }

            // 栏遮罩，不挡滑动，靠透明度淡入淡出
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .opacity(showControls ? 1 : 0)

            // 顶部控制栏，同样用透明度控制显隐
            VStack {
                HStack {
                    Button { onBack?() ?? dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                    }
                    .accessibilityLabel("返回")
                    Spacer()
                    Button { showActionSheet = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                    }
                    .accessibilityLabel("更多")
                }
                .padding(.horizontal, 20)
                // 往下挪，避开状态栏和灵动岛
                .padding(.top, 60)
                Spacer()
            }
            .opacity(showControls ? 1 : 0)
            .allowsHitTesting(showControls)
            // 切换标签时只有这两个按钮跟着滑，背景和遮罩都待着不动
            .offset(x: slideOffset)

            // 保存成功横幅
            if showSavedBanner {
                Text(L("image_saved"))
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.7), in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 70)
                    .transition(.opacity)
            }

            // 动作面板遮罩，点掉关闭
            if showActionSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showActionSheet = false }
                    .transition(.opacity)
            }

            // 底部动作面板，自身就是玻璃卡片，不包 sheet 容器
            if showActionSheet {
                VStack {
                    Spacer()
                    DetailActionSheet(
                        onSaveImage: { showActionSheet = false; saveCurrentImage() },
                        onEditTitle: { showActionSheet = false; beginEditTitle() },
                        onChangeBackground: { showActionSheet = false; showPhotoPicker = true },
                        onAdjustDate: { showActionSheet = false; showDatePicker = true }
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showControls.toggle() }
        .animation(.easeInOut(duration: 0.25), value: showControls)
        .animation(.snappy(duration: 0.3), value: showActionSheet)
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        // 详情页隐藏状态栏 iOS 26
        // 页面在状态栏区域自动渲染透明背板，代码删不掉
        // 顶部没有时间电量了 T T
        .statusBarHidden(true)
        // 量一下屏幕尺寸，给保存图片渲染用
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { screenSize = proxy.size }
            }
        )
        .alert(L("edit_title"), isPresented: $showTitleEdit) {
            TextField(L("name_this_moment"), text: $draftTitle)
            Button(L("confirm")) { saveTitle() }
            Button(L("cancel"), role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                // 先缩到合理尺寸再存，避免原图撑爆布局和体积
                currentEvent?.backgroundImageName = ImageUtils.saveBackground(uiImage)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(initialDate: currentEvent?.targetDate ?? Date()) { newDate in
                // 数据库自动存
                if let event = currentEvent {
                    event.targetDate = newDate
                    event.isFuture = newDate > Date()
                    event.mode = newDate > Date() ? .countDown : .accumulate
                }
            }
        }
    }

    // 垂直无限分页器
    private var pager: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(0..<Self.virtualCount, id: \.self) { i in
                        EventPosterView(event: events[i % events.count], isCurrentPage: currentPage == i)
                            .id(i)
                            .containerRelativeFrame(.vertical)
                            // 每页背景延伸到状态栏下面，顶到最顶
                            .ignoresSafeArea(edges: .top)
                    }
                }
                // 海报内容延伸到状态栏下面，盖住顶部那条固定的黑带
                .ignoresSafeArea(edges: .top)
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
            // 滚动时实时算页码，但先存着就好w，动画是停稳的事
            .onScrollGeometryChange(for: Int.self) { geometry in
                Int((geometry.contentOffset.y / geometry.containerSize.height).rounded())
            } action: { _, page in
                computedPage = page
            }
            // 等滚动停稳了才提交当前页
            .onScrollPhaseChange { _, newPhase in
                if newPhase == .idle {
                    currentPage = computedPage
                    // 记
                    UserDefaults.standard.set(computedPage, forKey: Self.resumeKey)
                }
            }
            // 用 scrollTo 这种更可靠的方法跳到起始页
            // 这样上下让两边都有巨大缓冲，才能形成无限循环www
            .onAppear {
                proxy.scrollTo(startPage, anchor: .top)
            }
            .background(ScrollToTopDisabled())
            .onChange(of: reselectTick) { _, _ in
                let n = max(events.count, 1)
                let groupTop = currentPage - (currentPage % n)
                withAnimation(.easeOut(duration: 0.35)) {
                    proxy.scrollTo(groupTop, anchor: .top)
                }
            }
        }
    }

    // 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chevron.left")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.6))
            Text(L("no_data"))
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    // 当前页事件
    private var currentEvent: DateEvent? {
        guard events.indices.contains(currentPage % events.count) else { return nil }
        return events[currentPage % events.count]
    }

    // 改标题准备
    private func beginEditTitle() {
        draftTitle = currentEvent?.title ?? ""
        showTitleEdit = true
    }

    private func saveTitle() {
        let t = draftTitle.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty {
            currentEvent?.title = t
        }
        showTitleEdit = false
    }

    // 把当前页的没 UI 版本保存成干净图片
    private func saveCurrentImage() {
        guard let currentEvent, screenSize.width > 0, screenSize.height > 0 else { return }
        let renderer = ImageRenderer(
            content: PosterContent(event: currentEvent, days: TimeUtils.daysBetween(targetDate: currentEvent.targetDate))
                .frame(width: screenSize.width, height: screenSize.height)
        )
        renderer.scale = displayScale
        guard let image = renderer.uiImage else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            Task { @MainActor in
                withAnimation { showSavedBanner = true }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation { showSavedBanner = false }
            }
        }
    }
}

#Preview("详情页") {
    DetailScreen(events: MockData.sampleEvents, initialEventId: MockData.sampleEvents[0].id)
}

// 把底层逻辑回顶部关掉
private struct ScrollToTopDisabled: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        // 往父链上找最近 UIScrollView 关回顶
        DispatchQueue.main.async {
            var node = view.superview
            while let current = node {
                if let scroll = current as? UIScrollView {
                    scroll.scrollsToTop = false
                    break
                }
                node = current.superview
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
