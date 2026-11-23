import SwiftUI
import SwiftData

// 设置页

struct SettingsScreen: View {
    // 日夜模式
    @AppStorage(AppPreferenceKeys.themeMode) private var themeModeRaw = ThemeMode.system.rawValue
    // 语言模式
    @AppStorage(AppPreferenceKeys.languageMode) private var languageModeRaw = LanguageMode.system.rawValue

    // 弹层开关
    @State private var showThemePicker = false
    @State private var showLanguagePicker = false
    @State private var showAnimations = false
    @AppStorage(AppPreferenceKeys.tabAnimations) private var tabAnimationsOn = true
    // 详情页天数跳动动画开关
    @AppStorage(AppPreferenceKeys.dayCountAnimation) private var dayCountAnimOn = true
    @State private var showDevelopingAlert = false
    @State private var showBackupFlow = false
    // 感谢糖方喵
    @State private var showPublisherAlert = false
    // 决定弹窗文案
    @State private var developingFeature = ""

    // 当前日夜模式
    private var themeMode: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .system }
    // 当前语言模式
    private var languageMode: LanguageMode { LanguageMode(rawValue: languageModeRaw) ?? .system }
    @Environment(\.tabSlideOffset) private var slideOffset
    // 前景淡入
    @Environment(\.tabReveal) private var reveal

    var body: some View {
        ZStack(alignment: .top) {
            // 底色钉住
            TimeTracePalette.background.ignoresSafeArea()

            // 前景
            ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 20) {
                generalSection
                dataSection
                aboutSection
                brandFooter
            }
            .padding(.top, 108)
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Text(L("settings_title"))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(TimeTracePalette.onSurface)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .zIndex(1)

            // 日夜模
            if showThemePicker {
                GlassCenterPicker(
                    title: L("theme_mode"),
                    options: ThemeMode.allCases.map { GlassOption(id: $0.rawValue, icon: themeIcon($0), title: $0.label) },
                    selectedID: themeModeRaw,
                    onSelect: { id in
                        themeModeRaw = id
                        withAnimation { showThemePicker = false }
                    },
                    onDismiss: { withAnimation { showThemePicker = false } }
                )
                .zIndex(2)
            }

            // 语言选择
            if showLanguagePicker {
                GlassCenterPicker(
                    title: L("language_selection"),
                    options: languageOptions,
                    selectedID: languageModeRaw,
                    onSelect: { id in
                        languageModeRaw = id
                        // 先把语言换好再让界面重建
                        LanguageManager.apply(LanguageMode(rawValue: id)?.localeIdentifier)
                        withAnimation { showLanguagePicker = false }
                    },
                    onDismiss: { withAnimation { showLanguagePicker = false } }
                )
                .zIndex(2)
            }
            }
            .offset(x: slideOffset)
            .opacity(reveal)

            // 居中
            if showAnimations {
                animationPanel
                    .zIndex(3)
                    .transition(.opacity.combined(with: .scale(0.96)))
            }
        }
        // 重建这棵界面树
        // 设置页在自己也带一份
        .id(languageModeRaw)
        // 套用选中的日夜模式，单独跑设置页时也能看出效果
        .preferredColorScheme(themeMode.colorScheme)
        // 切换弹层时用轻弹簧动画
        .animation(.spring(duration: 0.35, bounce: 0.25), value: showThemePicker)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: showLanguagePicker)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: showAnimations)
        // 开发中提示
        .alert(L("confirm"), isPresented: $showDevelopingAlert) {
            Button(L("confirm"), role: .cancel) {}
        } message: {
            Text(developingFeature == "about_app"
                 ? "\(L("about_app"))\n\(L("about_maintenance"))"
                 : String(format: L("feature_developing"), L(developingFeature)))
        }
        // 切换日夜模式和语言时给个轻微震动
        .sensoryFeedback(.selection, trigger: themeModeRaw)
        .sensoryFeedback(.selection, trigger: languageModeRaw)
        // 点发行方后看公司全称
        .alert("Candy Rectangle", isPresented: $showPublisherAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Published by Shanghai Candy Rectangle Technology Co., Ltd.")
        }
        // 数据备份与恢复
        .backupFlow(isPresented: $showBackupFlow)
        // 官方这个弹窗是不认内部控件的 tint 的....所以我写外面来了..@ @
        .tint(TimeTracePalette.primary)
    }

    // 浮层
    private var animationPanel: some View {
        ZStack {
            // 半透明遮罩，点它就把弹窗收起来，和日夜模式、语言那两个弹窗一个路子
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showAnimations = false }

            VStack(spacing: 20) {
                Text(L("animation_effects"))
                    .font(.headline)
                    .foregroundStyle(TimeTracePalette.onSurface)

                VStack(spacing: 0) {
                    animToggleRow(L("tab_slide_animation"), isOn: $tabAnimationsOn)
                    hairline
                    animToggleRow(L("detail_day_animation"), isOn: $dayCountAnimOn)
                }
            }
            .padding(20)
            .frame(width: 320)
            // 玻璃卡片
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    // 一行
    private func animToggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(TimeTracePalette.onSurface)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(TimeTracePalette.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // 细线
    private var hairline: some View {
        Rectangle()
            .fill(TimeTracePalette.outline.opacity(0.3))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    // 通用设置
    private var generalSection: some View {
        SettingsSection(title: L("section_general")) {
            SettingsItem(icon: "moon.fill", title: L("theme_mode"), subtitle: themeMode.label) {
                withAnimation { showThemePicker = true }
            }
            divider
            SettingsItem(icon: "globe", title: L("language_selection"), subtitle: languageMode.label) {
                withAnimation { showLanguagePicker = true }
            }
            divider
            SettingsItem(icon: "wand.and.stars", title: L("animation_effects"), subtitle: L("animation_effects_subtitle")) {
                showAnimations = true
            }
        }
    }

    // 数据安全
    private var dataSection: some View {
        SettingsSection(title: L("section_data")) {
            SettingsItem(icon: "externaldrive.badge.checkmark", title: L("backup_restore"), subtitle: L("local_backup_subtitle")) {
                showBackupFlow = true
            }
        }
    }

    // 关于分区
    private var aboutSection: some View {
        SettingsSection(title: L("section_about")) {
            SettingsItem(icon: "info.circle", title: L("about_app"), subtitle: "\(appVersion) Stable") {
                developingFeature = "about_app"
                showDevelopingAlert = true
            }
            divider
            // 详细公司信息
            SettingsItem(icon: "shippingbox", title: L("publisher_title"), subtitle: "Publisher") {
                showPublisherAlert = true
            }
        }
    }

    // 底部
    private var brandFooter: some View {
        VStack(spacing: 4) {
            Text("TimeTrace")
                .font(.footnote.weight(.medium))
                .tracking(2)
                .foregroundStyle(TimeTracePalette.primary.opacity(0.5))
            Text("© 2026 KIPPU. Licensed under MIT.")
                .font(.caption2)
                .foregroundStyle(TimeTracePalette.onSurfaceVariant.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // 细分割线
    private var divider: some View {
        Rectangle()
            .fill(TimeTracePalette.outline.opacity(0.3))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    // 版本
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(version)"
    }

    // 日夜模式三档各自的图标
    private func themeIcon(_ mode: ThemeMode) -> String {
        switch mode {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    // 语言模式四档各自的图标
    private var languageOptions: [GlassOption] {
        LanguageMode.allCases.map { mode in
            let icon: String
            let iconText: String?
            switch mode {
            case .system: icon = "globe"; iconText = nil
            case .chinese: icon = "character.book.closed.zh"; iconText = nil
            case .english: icon = "a.circle"; iconText = nil
            case .japanese: icon = ""; iconText = "あ"
            }
            return GlassOption(id: mode.rawValue, icon: icon, title: mode.label, iconText: iconText)
        }
    }
}

#Preview("设置页浅色模式") {
    SettingsScreen()
        .modelContainer(PresetData.previewContainer())
}

#Preview("设置页深色模式") {
    SettingsScreen()
        .modelContainer(PresetData.previewContainer())
        .preferredColorScheme(.dark)
}
