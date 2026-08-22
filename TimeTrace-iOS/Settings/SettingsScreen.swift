import SwiftUI

// 设置页

struct SettingsScreen: View {
    // 日夜模式
    @AppStorage(AppPreferenceKeys.themeMode) private var themeModeRaw = ThemeMode.system.rawValue
    // 语言模式
    @AppStorage(AppPreferenceKeys.languageMode) private var languageModeRaw = LanguageMode.system.rawValue

    // 弹窗开关
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
        NavigationStack {
            List {
                generalSection
                dataSection
                aboutSection
                brandFooter
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(TimeTracePalette.background)
            .navigationTitle("我的")
            // 日夜模式三档
            .confirmationDialog("日夜模式", isPresented: $showThemePicker, titleVisibility: .visible) {
                ForEach(ThemeMode.allCases) { mode in
                    Button { themeModeRaw = mode.rawValue } label: {
                        if mode == themeMode {
                            Label(mode.label, systemImage: "checkmark")
                        } else {
                            Text(mode.label)
                        }
                    }
                }
            }
            // 语言模式四档
            .confirmationDialog("语言选择", isPresented: $showLanguagePicker, titleVisibility: .visible) {
                ForEach(LanguageMode.allCases) { mode in
                    Button { languageModeRaw = mode.rawValue } label: {
                        if mode == languageMode {
                            Label(mode.label, systemImage: "checkmark")
                        } else {
                            Text(mode.label)
                        }
                    }
                }
            }
            // 开发中提示
            .alert("确定", isPresented: $showDevelopingAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(developingFeature == "关于时痕"
                     ? "关于时痕\nMaintained by KIPPU"
                     : "「\(developingFeature)」功能正在开发中，敬请期待！")
            }
        }
        // 切换日夜模式和语言时给个轻微震动
        .sensoryFeedback(.selection, trigger: themeModeRaw)
        .sensoryFeedback(.selection, trigger: languageModeRaw)
    }

    // 通用设置
    private var generalSection: some View {
        SettingsSection(title: "通用设置") {
            SettingsItem(icon: "moon.fill", title: "日夜模式", subtitle: themeMode.label) {
                showThemePicker = true
            }
            divider
            SettingsItem(icon: "globe", title: "语言选择", subtitle: languageMode.label) {
                showLanguagePicker = true
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    // 数据安全
    private var dataSection: some View {
        SettingsSection(title: "数据安全") {
            SettingsItem(icon: "externaldrive.badge.checkmark", title: "数据备份与恢复", subtitle: "本地导入/导出") {
                developingFeature = "数据备份与恢复"
                showDevelopingAlert = true
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    // 关于分区
    private var aboutSection: some View {
        SettingsSection(title: "关于") {
            SettingsItem(icon: "info.circle", title: "关于时痕", subtitle: "\(appVersion) Stable") {
                developingFeature = "关于时痕"
                showDevelopingAlert = true
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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
}

#Preview("设置页浅色模式") {
    SettingsScreen()
}

#Preview("设置页深色模式") {
    SettingsScreen()
        .preferredColorScheme(.dark)
}
