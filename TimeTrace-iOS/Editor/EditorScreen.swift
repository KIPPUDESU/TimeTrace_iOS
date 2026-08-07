import SwiftUI

// 全屏编辑
struct EditorScreen: View {
    var onDismiss: () -> Void
    var onSave: (DateEvent) -> Void

    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var isPinned = false
    @State private var maskOpacity: Double = 0.4
    @State private var mode: DisplayMode = .countDown
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    titleSection
                    optionCards
                    modeSection
                    pinRow
                    maskRow
                    pinnedPreview
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .background(TimeTracePalette.background)
            .navigationTitle("编辑时痕")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("关闭")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("保存")
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(initialDate: selectedDate) { newDate in
                    selectedDate = newDate
                    // 日期变更自动切换模式
                    mode = newDate > Date() ? .countDown : .accumulate
                }
            }
        }
    }

    // 标题输入框
    private var titleSection: some View {
        VStack(spacing: 4) {
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
            .frame(height: 56)
            .background(TimeTracePalette.surfaceVariant.opacity(0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TimeTracePalette.outline, lineWidth: 1.5)
            )

            // 实时显示标题的视觉宽度，和卡片排版用的算法一致
            Text(widthHint)
                .font(.caption)
                .foregroundStyle(TimeTracePalette.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var widthHint: String {
        let width = TimeTextUtils.visualWidth(of: title)
        let isPureEnglish = title.unicodeScalars.allSatisfy { $0.isASCII }
        return "当前视觉宽度: \(Int(width)) (\(isPureEnglish ? "英文/数字" : "中文字符"))"
    }

    // 设定日期和背景图片两个并排卡片
    private var optionCards: some View {
        HStack(spacing: 12) {
            Button { showDatePicker = true } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode == .countDown ? "目标日期" : "起始日期")
                        .font(.caption)
                        .foregroundStyle(TimeTracePalette.onSurfaceVariant)
                    Text(TimeUtils.shortDate(selectedDate))
                        .font(.headline)
                        .foregroundStyle(TimeTracePalette.onSurface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(TimeTracePalette.onSurface.opacity(0.03), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            // 背景图：相册选择等数据层落地后再接
            Button { } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("背景图片")
                        .font(.caption)
                        .foregroundStyle(TimeTracePalette.onSurfaceVariant)
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                        Text("点击选择")
                            .font(.headline)
                    }
                    .foregroundStyle(TimeTracePalette.onSurface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(TimeTracePalette.onSurface.opacity(0.03), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // 倒数 / 累计模式，用 iOS 原生分段控件
    private var modeSection: some View {
        Picker("模式", selection: $mode) {
            Text("倒数模式").tag(DisplayMode.countDown)
            Text("累计模式").tag(DisplayMode.accumulate)
        }
        .pickerStyle(.segmented)
        // 用大号分段控件，抬高一点更接近安卓的胶囊切换
        .controlSize(.large)
        .sensoryFeedback(.selection, trigger: mode)
    }

    private var pinRow: some View {
        HStack {
            Text("在首页置顶展示")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $isPinned)
                .labelsHidden()
                .sensoryFeedback(.impact(weight: .light), trigger: isPinned)
        }
    }

    private var maskRow: some View {
        VStack(spacing: 8) {
            HStack {
                Text("遮罩强度")
                    .font(.headline)
                Spacer()
                Text("\(Int(maskOpacity * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(TimeTracePalette.primary)
            }
            Slider(value: $maskOpacity, in: 0.1...0.9)
                // 拖拽条换成黑白灰的主色，浅色模式下就是黑
                .tint(TimeTracePalette.primary)
        }
        // 留空
        .padding(.top, 14)
    }

    // 实时预览编辑后的置顶卡片效果
    private var pinnedPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("置顶效果")
                // 中等次要的字号
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TimeTracePalette.secondary)
            PinnedEventCard(event: previewEvent) {}
        }
    }

    private var previewEvent: DateEvent {
        DateEvent(
            title: title.isEmpty ? "示例标题" : title,
            targetDate: selectedDate,
            isFuture: mode == .countDown,
            mode: mode,
            isPinned: true,
            maskOpacity: maskOpacity
        )
    }

    // 保存为新记录
    private func save() {
        onSave(DateEvent(
            title: title.isEmpty ? "无题" : title,
            targetDate: selectedDate,
            isFuture: mode == .countDown,
            mode: mode,
            isPinned: isPinned,
            maskOpacity: maskOpacity
        ))
    }
}

// 预览用
#Preview("编辑页浅色模式") {
    EditorScreen(onDismiss: {}, onSave: { _ in })
}

#Preview("编辑页深色模式") {
    EditorScreen(onDismiss: {}, onSave: { _ in })
        .preferredColorScheme(.dark)
}
