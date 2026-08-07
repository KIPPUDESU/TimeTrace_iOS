import SwiftUI
import PhotosUI

// 编辑页面
struct EditEventSheet: View {
    @Binding var event: DateEvent
    var onSave: (DateEvent) -> Void
    var onCancel: () -> Void

    @State private var title: String
    @State private var showDatePicker = false
    @State private var pickerItem: PhotosPickerItem?

    init(event: Binding<DateEvent>, onSave: @escaping (DateEvent) -> Void, onCancel: @escaping () -> Void) {
        self._event = event
        self._title = State(initialValue: event.wrappedValue.title)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        // 去掉滚动，内容固定在一屏，并顶到容器上方
        VStack(spacing: 20) {
            Text("编辑时痕")
                .font(.title.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                // 标题往下留一点，避开顶部的引导线
                .padding(.top, 24)

            titleField
            optionCards
            modeSwitcher
            pinRow
            maskRow
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        // 禁止滚动后，需要主动顶到容器上方
        .frame(maxHeight: .infinity, alignment: .top)
        .background(TimeTracePalette.surface)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(initialDate: event.targetDate) { newDate in
                event.targetDate = newDate
                event.isFuture = newDate > Date()
                event.mode = newDate > Date() ? .countDown : .accumulate
            }
        }
    }

    // 编辑页标题
    private var titleField: some View {
        ZStack(alignment: .leading) {
            if title.isEmpty {
                Text("给这一刻起个名字")
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
                    Text(event.mode == .countDown ? "目标日期" : "起始日期")
                        .font(.caption)
                        .foregroundStyle(TimeTracePalette.onSurfaceVariant)
                    Text(TimeUtils.shortDate(event.targetDate))
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
                    Text("背景图片")
                        .font(.caption)
                        .foregroundStyle(TimeTracePalette.onSurfaceVariant)
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                        Text(event.backgroundImageName == nil ? "点击选择" : "已选择")
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
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("bg-\(UUID().uuidString).jpg")
                    guard let jpeg = uiImage.jpegData(compressionQuality: 0.85) else { return }
                    try? jpeg.write(to: url)
                    event.backgroundImageName = url.path
                }
            }
        }
    }

    // 模式 置顶 遮罩
    private var modeSwitcher: some View {
        Picker("模式", selection: $event.mode) {
            Text("倒数模式").tag(DisplayMode.countDown)
            Text("累计模式").tag(DisplayMode.accumulate)
        }
        .pickerStyle(.segmented)
        // 和全屏编辑器一致，用大号分段控件
        .controlSize(.large)
        .sensoryFeedback(.selection, trigger: event.mode)
    }
    // 是否置顶
    private var pinRow: some View {
        HStack {
            Text("在首页置顶展示")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $event.isPinned)
                .labelsHidden()
                // 开关底色从默认绿换成主色黑
                .tint(TimeTracePalette.primary)
                .sensoryFeedback(.impact(weight: .light), trigger: event.isPinned)
        }
    }

    private var maskRow: some View {
        VStack(spacing: 8) {
            HStack {
                Text("遮罩强度")
                    .font(.headline)
                Spacer()
                Text("\(Int(event.maskOpacity * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(TimeTracePalette.primary)
            }
            Slider(value: $event.maskOpacity, in: 0.1...0.9)
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
                Text("确定")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(TimeTracePalette.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(TimeTracePalette.onPrimary)
            }
            .buttonStyle(.plain)

            Button(action: onCancel) {
                Text("取消")
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

    private func save() {
        var updated = event
        updated.title = title.isEmpty ? "无题" : title
        updated.isFuture = updated.targetDate > Date()
        onSave(updated)
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
            DatePicker("选择日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                // 选中还有今天标记这些指示色从蓝换成主色黑
                .tint(TimeTracePalette.primary)
                // 锁死日历高度，sheet 拉伸时日历不再重新排版，杜绝边距缩小 bug
                .frame(height: 420)
                // 强制用简体中文，不然日历的月份星期会跟着系统语言走
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .padding()
                .navigationTitle("选择日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确定") { onConfirm(date); dismiss() }
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
        event: .constant(MockData.sampleEvents[0]),
        onSave: { _ in },
        onCancel: {}
    )
}
