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

    init() {
        container = try! ModelContainer(for: DateEvent.self)
        // 第一次打开时如果库里是空的，放几条样例进去
        MockData.seedIfEmpty(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
