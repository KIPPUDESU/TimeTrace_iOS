import SwiftUI

// 设置页

struct SettingsScreen: View {
    // 日夜模式
    @AppStorage(AppPreferenceKeys.themeMode) private var themeModeRaw = ThemeMode.system.rawValue
    // 语言模式
    @AppStorage(AppPreferenceKeys.languageMode) private var languageModeRaw = LanguageMode.system.rawValue

    // 弹层开关
    @State private var showThemePicker = false
    @State private var showLanguagePicker = false
    @State private var showDevelopingAlert = false
    // 决定弹窗文案
    @State private var developingFeature = ""

    // 当前日夜模式
    private var themeMode: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .system }
    // 当前语言模式
    private var languageMode: LanguageMode { LanguageMode(rawValue: languageModeRaw) ?? .system }

    var body: some View {
        ZStack(alignment: .top) {
            // 页面底色从上到下铺满
            TimeTracePalette.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    generalSection
                    dataSection
                    aboutSection
                    brandFooter
                }
                .padding(.top, 108)
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)

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
        // 重建这棵界面树
        // 设置页在自己也带一份
        .id(languageModeRaw)
        // 套用选中的日夜模式，单独跑设置页时也能看出效果
        .preferredColorScheme(themeMode.colorScheme)
        // 切换弹层时用轻弹簧动画
        .animation(.spring(duration: 0.35, bounce: 0.25), value: showThemePicker)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: showLanguagePicker)
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
        }
    }

    // 数据安全
    private var dataSection: some View {
        SettingsSection(title: L("section_data")) {
            SettingsItem(icon: "externaldrive.badge.checkmark", title: L("backup_restore"), subtitle: L("local_backup_subtitle")) {
                developingFeature = "backup_restore"
                showDevelopingAlert = true
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
}

#Preview("设置页深色模式") {
    SettingsScreen()
        .preferredColorScheme(.dark)
}
