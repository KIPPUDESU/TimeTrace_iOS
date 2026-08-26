import SwiftUI
import PhotosUI

// 编辑页面
// 先改草稿，确定写数据库，取消什么都不动
struct EditEventSheet: View {
    let event: DateEvent
    var onSave: () -> Void
    var onCancel: () -> Void

    @State private var title: String
    @State private var selectedDate: Date
    @State private var isPinned: Bool
    @State private var maskOpacity: Double
    @State private var mode: DisplayMode
    @State private var backgroundImageName: String?
    @State private var showDatePicker = false
    @State private var pickerItem: PhotosPickerItem?

    init(event: DateEvent, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.event = event
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: event.title)
        _selectedDate = State(initialValue: event.targetDate)
        _isPinned = State(initialValue: event.isPinned)
        _maskOpacity = State(initialValue: event.maskOpacity)
        _mode = State(initialValue: event.mode)
        _backgroundImageName = State(initialValue: event.backgroundImageName)
    }

    var body: some View {
        // 去掉滚动，内容固定在一屏，并顶到容器上方
        VStack(spacing: 20) {
            Text("edit_timetrace")
                .font(.title.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                // 标题往下留一点，避开顶部的引导线
                .padding(.top, 80)

            titleField
            optionCards
            modeSwitcher
            pinRow
            maskRow
            actionButtons
            // 撑满剩余空间，把内容顶到最上面，半屏时标题也不会被挤没
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        // 禁止滚动后，需要主动顶到容器上方
        .frame(maxHeight: .infinity, alignment: .top)
        .background(TimeTracePalette.surface)
        // 舍弃半屏，固定高 700，不到全屏
        .presentationDetents([.height(580)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(initialDate: selectedDate) { newDate in
                selectedDate = newDate
                // 日期变更自动切换模式
                mode = newDate > Date() ? .countDown : .accumulate
            }
        }
    }

    // 编辑页标题
    private var titleField: some View {
        ZStack(alignment: .leading) {
            if title.isEmpty {
                Text("name_this_moment")
                    .font(.body)
                    .foregroundStyle(TimeTracePalette.onSurfaceVariant.opacity(0.6))
            }
            TextField("", text: $title)
                .font(.body)
                .foregroundStyle(TimeTracePalette.onSurface)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(TimeTracePalette.surfaceVariant.opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TimeTracePalette.outline, lineWidth: 1.5)
        )
    }

    // 设定日期
    private var optionCards: some View {
        HStack(spacing: 12) {
            Button { showDatePicker = true } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode == .countDown ? "target_date_label" : "start_date_label")
                        .font(.caption)
                        .foregroundStyle(TimeTracePalette.onSurfaceVariant)
                    Text(TimeUtils.shortDate(selectedDate))
                        .font(.headline)
                        .foregroundStyle(TimeTracePalette.onSurface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(TimeTracePalette.onSurface.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("background_image_label")
                        .font(.caption)
                        .foregroundStyle(TimeTracePalette.onSurfaceVariant)
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                        Text(backgroundImageName == nil ? "tap_to_select" : "selected_label")
                            .font(.headline)
                    }
                    .foregroundStyle(TimeTracePalette.onSurface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(TimeTracePalette.onSurface.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data) else { return }
                    // 先缩到合理尺寸再存，避免原图撑爆布局和体积
                    let resized = ImageUtils.downscaled(uiImage)
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("bg-\(UUID().uuidString).jpg")
                    guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return }
                    try? jpeg.write(to: url)
                    backgroundImageName = url.path
                }
            }
        }
    }

    // 模式 置顶 遮罩
    private var modeSwitcher: some View {
        Picker("mode", selection: $mode) {
            Text("countdown_mode").tag(DisplayMode.countDown)
            Text("accumulate_mode").tag(DisplayMode.accumulate)
        }
        .pickerStyle(.segmented)
        // 和全屏编辑器一致，用大号分段控件
        .controlSize(.large)
        .sensoryFeedback(.selection, trigger: mode)
    }
    // 是否置顶
    private var pinRow: some View {
        HStack {
            Text("pin_to_top")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $isPinned)
                .labelsHidden()
                // 开关底色从默认绿换成主色黑
                .tint(TimeTracePalette.primary)
                .sensoryFeedback(.impact(weight: .light), trigger: isPinned)
        }
    }

    private var maskRow: some View {
        VStack(spacing: 8) {
            HStack {
                Text("mask_intensity")
                    .font(.headline)
                Spacer()
                Text("\(Int(maskOpacity * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(TimeTracePalette.primary)
            }
            Slider(value: $maskOpacity, in: 0.1...0.9)
                // 和全屏编辑器一致，拖拽条用主色
                .tint(TimeTracePalette.primary)
        }
        // 留空
        .padding(.top, 10)
    }

    // 最后的确定操作呢
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: save) {
                Text("confirm")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(TimeTracePalette.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(TimeTracePalette.onPrimary)
            }
            .buttonStyle(.plain)

            Button(action: onCancel) {
                Text("cancel")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(TimeTracePalette.outline, lineWidth: 1.5)
                    )
                    .foregroundStyle(TimeTracePalette.onSurface)
            }
            .buttonStyle(.plain)
        }
        // 留空
        .padding(.top, 6)
    }

    // 把草稿写回这条记录
    private func save() {
        event.title = title.isEmpty ? String(localized: "untitled") : title
        event.targetDate = selectedDate
        event.isFuture = selectedDate > Date()
        event.mode = mode
        event.isPinned = isPinned
        event.maskOpacity = maskOpacity
        event.backgroundImageName = backgroundImageName
        onSave()
    }
}

/// 原生日期选择，用我们苹果小子的原生
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    var onConfirm: (Date) -> Void

    init(initialDate: Date, onConfirm: @escaping (Date) -> Void) {
        self._date = State(initialValue: initialDate)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            DatePicker("select_date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                // 选中还有今天标记这些指示色从蓝换成主色黑
                .tint(TimeTracePalette.primary)
                // 锁死日历高度，sheet 拉伸时日历不再重新排版，杜绝边距缩小 bug
                .frame(height: 420)
                // 强制用简体中文，不然日历的月份星期会跟着系统语言走
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .padding()
                .navigationTitle("select_date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("confirm") { onConfirm(date); dismiss() }
                    }
                }
        }
        // 矮档
        .presentationDetents([.height(460), .large])
    }
}

// 给预览
#Preview("编辑面板") {
    EditEventSheet(
        event: MockData.sampleEvents[0],
        onSave: {},
        onCancel: {}
    )
}
