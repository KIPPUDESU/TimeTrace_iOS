import SwiftUI
import PhotosUI

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
    // 背景图的文件路径，没选就是 nil
    @State private var backgroundImageName: String?
    // 照片选择器选中的
    @State private var pickerItem: PhotosPickerItem?

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
                    fullScreenPreview
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .background(TimeTracePalette.background)
            .navigationTitle(L("edit_timetrace"))
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
                    Text(L("name_this_moment"))
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
        let category = L(isPureEnglish ? "english_numbers_label" : "chinese_characters_label")
        return String(format: L("visual_width_format"), width, category)
    }

    // 设定日期和背景图片两个并排卡片
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
                .background(TimeTracePalette.onSurface.opacity(0.03), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            // 点开系统相册选一张，压缩存进 Documents 记录好路径w
            PhotosPicker(selection: $pickerItem, matching: .images) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("background_image_label"))
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
                .background(TimeTracePalette.onSurface.opacity(0.03), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    // 倒数 / 累计模式，用 iOS 原生分段控件
    private var modeSection: some View {
        Picker("mode", selection: $mode) {
            Text(L("countdown_mode")).tag(DisplayMode.countDown)
            Text(L("accumulate_mode")).tag(DisplayMode.accumulate)
        }
        .pickerStyle(.segmented)
        // 用大号分段控件，抬高一点更接近安卓的胶囊切换
        .controlSize(.large)
        .sensoryFeedback(.selection, trigger: mode)
    }

    private var pinRow: some View {
        HStack {
            Text(L("pin_to_top"))
                .font(.headline)
            Spacer()
            Toggle("", isOn: $isPinned)
                .labelsHidden()
                // 绿换成主色黑
                .tint(TimeTracePalette.primary)
                .sensoryFeedback(.impact(weight: .light), trigger: isPinned)
        }
    }

    private var maskRow: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L("mask_intensity"))
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
            Text(L("pinned_preview"))
                // 中等次要的字号
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TimeTracePalette.secondary)
            // 外层锁死宽度，防止卡片内部 aspectRatio 在滚动视图里被图片自然尺寸撑宽
            GeometryReader { geo in
                PinnedEventCard(event: previewEvent) {}
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
        }
    }

    // 全屏展示预览：复用详情页海报，实时看编辑后的详情页效果
    private var fullScreenPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("fullscreen_preview"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TimeTracePalette.secondary)
            // 用 GeometryReader 锁死实际内容宽度，防止图片按自然宽度把页面撑宽
            GeometryReader { geo in
                PosterContent(
                    event: previewEvent,
                    days: TimeUtils.daysBetween(targetDate: previewEvent.targetDate),
                    showsTime: false,
                    // 预览不是真全屏，字号按比例缩小
                    scale: 0.55
                )
                .frame(width: geo.size.width, height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .frame(height: 500)
        }
    }

    private var previewEvent: DateEvent {
        DateEvent(
            title: title.isEmpty ? L("sample_title") : title,
            targetDate: selectedDate,
            isFuture: mode == .countDown,
            mode: mode,
            backgroundImageName: backgroundImageName,
            isPinned: true,
            maskOpacity: maskOpacity
        )
    }

    // 保存为新记录
    private func save() {
        onSave(DateEvent(
            title: title.isEmpty ? L("untitled") : title,
            targetDate: selectedDate,
            isFuture: mode == .countDown,
            mode: mode,
            backgroundImageName: backgroundImageName,
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
