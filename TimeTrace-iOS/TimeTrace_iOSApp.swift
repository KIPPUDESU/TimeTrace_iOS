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
        // 第一次打开时如果库里是空的，放几条样例进去
        MockData.seedIfEmpty(in: container.mainContext)
        // 启动时应用已保存的语言偏好
        applyLanguage()
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
