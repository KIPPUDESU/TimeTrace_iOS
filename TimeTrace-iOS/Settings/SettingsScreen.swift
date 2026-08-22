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

            Text("我的")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(TimeTracePalette.onSurface)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .zIndex(1)

            // 日夜模
            if showThemePicker {
                GlassCenterPicker(
                    title: "日夜模式",
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
                    title: "语言选择",
                    options: languageOptions,
                    selectedID: languageModeRaw,
                    onSelect: { id in
                        languageModeRaw = id
                        withAnimation { showLanguagePicker = false }
                    },
                    onDismiss: { withAnimation { showLanguagePicker = false } }
                )
                .zIndex(2)
            }
        }
        // 切换弹层时用轻弹簧动画
        .animation(.spring(duration: 0.35, bounce: 0.25), value: showThemePicker)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: showLanguagePicker)
        // 开发中提示
        .alert("确定", isPresented: $showDevelopingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(developingFeature == "关于时痕"
                 ? "关于时痕\nMaintained by KIPPU"
                 : "「\(developingFeature)」功能正在开发中，敬请期待！")
        }
        // 切换日夜模式和语言时给个轻微震动
        .sensoryFeedback(.selection, trigger: themeModeRaw)
        .sensoryFeedback(.selection, trigger: languageModeRaw)
    }

    // 通用设置
    private var generalSection: some View {
        SettingsSection(title: "通用设置") {
            SettingsItem(icon: "moon.fill", title: "日夜模式", subtitle: themeMode.label) {
                withAnimation { showThemePicker = true }
            }
            divider
            SettingsItem(icon: "globe", title: "语言选择", subtitle: languageMode.label) {
                withAnimation { showLanguagePicker = true }
            }
        }
    }

    // 数据安全
    private var dataSection: some View {
        SettingsSection(title: "数据安全") {
            SettingsItem(icon: "externaldrive.badge.checkmark", title: "数据备份与恢复", subtitle: "本地导入/导出") {
                developingFeature = "数据备份与恢复"
                showDevelopingAlert = true
            }
        }
    }

    // 关于分区
    private var aboutSection: some View {
        SettingsSection(title: "关于") {
            SettingsItem(icon: "info.circle", title: "关于时痕", subtitle: "\(appVersion) Stable") {
                developingFeature = "关于时痕"
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
            case .chinese: icon = "character.book.closed"; iconText = nil
            case .english: icon = "textformat"; iconText = nil
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
