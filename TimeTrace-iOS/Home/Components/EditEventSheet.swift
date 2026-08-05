import SwiftUI

// 这个文件是编辑页面
struct EditEventSheet: View {
    @Binding var event: DateEvent
    var onSave: (DateEvent) -> Void
    var onCancel: () -> Void

    @State private var title: String
    @State private var showDatePicker = false

    init(event: Binding<DateEvent>, onSave: @escaping (DateEvent) -> Void, onCancel: @escaping () -> Void) {
        self._event = event
        self._title = State(initialValue: event.wrappedValue.title)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("编辑时痕")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                titleField
                optionCards
                modeSwitcher
                pinRow
                maskRow
                livePreview
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
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

            Button { /* 图片选择器落地后接 PhotosPicker */ } label: {
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
            .buttonStyle(.plain)
        }
    }

    // 想要的模式 置顶 遮罩
    private var modeSwitcher: some View {
        Picker("模式", selection: $event.mode) {
            Text("倒数模式").tag(DisplayMode.countDown)
            Text("累计模式").tag(DisplayMode.accumulate)
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: event.mode)
    }

    private var pinRow: some View {
        HStack {
            Text("在首页置顶展示")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $event.isPinned)
                .labelsHidden()
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
        }
    }

    // 直接预览作为置顶卡片和全屏详情的效果
    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("置顶效果")
                .font(.caption.weight(.medium))
                .foregroundStyle(TimeTracePalette.secondary)
            PinnedEventCard(event: previewEvent) {}
        }
    }

    private var previewEvent: DateEvent {
        DateEvent(
            title: title.isEmpty ? "示例标题" : title,
            targetDate: event.targetDate,
            isFuture: event.mode == .countDown,
            mode: event.mode,
            backgroundImageName: event.backgroundImageName,
            isPinned: true,
            maskOpacity: event.maskOpacity
        )
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
    }

    private func save() {
        var updated = event
        updated.title = title.isEmpty ? "无题" : title
        updated.isFuture = updated.targetDate > Date()
        onSave(updated)
    }
}

/// 原生日期选择（对应 Android `EditDatePickerDialog`）
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
        .presentationDetents([.medium, .large])
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
