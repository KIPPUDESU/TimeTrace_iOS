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
                // 语言切换时重新应用 Bundle 覆盖
                .onChange(of: languageModeRaw) { _, _ in applyLanguage() }
        }
        .modelContainer(container)
    }

    // 把语言偏好同步到 Bundle 层，让所有 String(localized:) 走对应 .lproj
    private func applyLanguage() {
        let mode = LanguageMode(rawValue: languageModeRaw) ?? .system
        Bundle.setLanguage(mode.localeIdentifier)
    }
}
