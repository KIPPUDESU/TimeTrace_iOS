import SwiftUI
import Photos
import PhotosUI

// 全屏详情页
struct DetailScreen: View {
    @Binding var events: [DateEvent]
    let initialEventId: Int64

    @Environment(\.dismiss) private var dismiss

    // 控制栏是否显示
    @State private var showControls = false
    // scrollPosition 双向绑定，只负责初始定位
    @State private var pageIndex: Int?
    // 几何算出的当前页
    @State private var currentPage: Int = 0
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

    init(events: Binding<[DateEvent]>, initialEventId: Int64) {
        self._events = events
        self.initialEventId = initialEventId
        let list = events.wrappedValue
        let idx = list.firstIndex(where: { $0.id == initialEventId }) ?? 0
        let n = list.count
        let half = Self.virtualCount / 2
        let computed = n > 1 ? half - (half % n) + idx : 0
        self.startPage = computed
        _pageIndex = State(initialValue: computed)
        _currentPage = State(initialValue: computed)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if events.isEmpty {
                emptyState
            } else {
                pager
            }

            // 栏遮罩，不挡滑动
            if showControls {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // 顶部控制栏
            if showControls {
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("返回")
                        Spacer()
                        Button { showActionSheet = true } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("更多")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    Spacer()
                }
                .transition(.opacity)
            }

            // 保存成功横幅
            if showSavedBanner {
                Text("图片已保存至相册")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.7), in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 70)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showControls.toggle() }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .sheet(isPresented: $showActionSheet) {
            DetailActionSheet(
                onSaveImage: { showActionSheet = false; saveCurrentImage() },
                onEditTitle: { showActionSheet = false; beginEditTitle() },
                onChangeBackground: { showActionSheet = false; showPhotoPicker = true },
                onAdjustDate: { showActionSheet = false; showDatePicker = true }
            )
            .presentationDetents([.height(360)])
            .presentationBackground(.clear)
        }
        .alert("修改标题", isPresented: $showTitleEdit) {
            TextField("给这一刻起个名字", text: $draftTitle)
            Button("确定") { saveTitle() }
            Button("取消", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("bg-\(UUID().uuidString).jpg")
                guard let jpeg = uiImage.jpegData(compressionQuality: 0.85) else { return }
                try? jpeg.write(to: url)
                updateCurrentEvent { $0.backgroundImageName = url.path }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(initialDate: currentEvent?.targetDate ?? Date()) { newDate in
                updateCurrentEvent { event in
                    event.targetDate = newDate
                    event.isFuture = newDate > Date()
                    event.mode = newDate > Date() ? .countDown : .accumulate
                }
            }
        }
    }

    // 垂直无限分页器
    private var pager: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(0..<Self.virtualCount, id: \.self) { i in
                    EventPosterView(event: events[i % events.count], isCurrentPage: currentPage == i)
                        .containerRelativeFrame(.vertical)
                }
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $pageIndex)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        // 滚动偏移一下就算出当前页，页码一变化就让新页重播动画
        .onScrollGeometryChange(for: Int.self) { geometry in
            Int((geometry.contentOffset.y / geometry.containerSize.height).rounded())
        } action: { _, page in
            currentPage = page
        }
        // 确保初始定位到被点的事件
        .onAppear { pageIndex = startPage }
    }

    // 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chevron.left")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.6))
            Text("请左滑在时间轴页中添加事件")
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

    // 修改当前页事件
    private func updateCurrentEvent(_ transform: (inout DateEvent) -> Void) {
        guard events.indices.contains(currentPage % events.count) else { return }
        let i = currentPage % events.count
        var e = events[i]
        transform(&e)
        events[i] = e
    }

    // 改标题准备
    private func beginEditTitle() {
        draftTitle = currentEvent?.title ?? ""
        showTitleEdit = true
    }

    private func saveTitle() {
        let t = draftTitle.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty {
            updateCurrentEvent { $0.title = t }
        }
        showTitleEdit = false
    }

    // 把当前页的没 UI 版本保存成干净图片
    private func saveCurrentImage() {
        guard let currentEvent else { return }
        let renderer = ImageRenderer(
            content: PosterContent(event: currentEvent, days: TimeUtils.daysBetween(targetDate: currentEvent.targetDate))
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        )
        renderer.scale = UIScreen.main.scale
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
    DetailScreen(events: .constant(MockData.sampleEvents), initialEventId: MockData.sampleEvents[0].id)
}
