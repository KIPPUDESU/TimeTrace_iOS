//
//  TimeTrace_iOSApp.swift
//  TimeTrace-iOS
//
//  Created by 切符 on 2026/8/2.
//

import SwiftUI
import SwiftData

@main
struct TimeTrace_iOSApp: App {
    // 共用的数据容器
    let container: ModelContainer
    // 监听语言切换
    @AppStorage(AppPreferenceKeys.languageMode) private var languageModeRaw = LanguageMode.system.rawValue
    // 强制 SwiftUI 重建全部视图
    @State private var refreshID = UUID()

    init() {
        container = try! ModelContainer(for: DateEvent.self)
        // 先应用语言，确保首次写入的预设标题使用当前语言
        applyLanguage()
        // 每次启动检查空库，正式包写入预设，开发包额外写入调试数据
        PresetData.seedIfEmpty(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 语言切换时重建视图树
                .id(refreshID)
                .onChange(of: languageModeRaw) { _, _ in
                    applyLanguage()
                    refreshID = UUID()
                }
        }
        .modelContainer(container)
    }

    private func applyLanguage() {
        let mode = LanguageMode(rawValue: languageModeRaw) ?? .system
        LanguageManager.apply(mode.localeIdentifier)
    }
}
