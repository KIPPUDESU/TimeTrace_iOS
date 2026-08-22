import Foundation
import SwiftData

// 样例与预览页假数据
enum MockData {
    static let sampleEvents: [DateEvent] = [
        DateEvent(
            id: 1,
            title: "きみのあと",
            targetDate: date(2026, 1, 1),
            isFuture: true,
            mode: .countDown,
            backgroundImageName: "graduation",
            isPinned: true,
            maskOpacity: 0.45
        ),
        DateEvent(
            id: 2,
            title: "俺を殺したいらしい",
            targetDate: date(2025, 3, 1),
            isFuture: false,
            mode: .accumulate,
            backgroundImageName: "newbg",
            isPinned: true,
            maskOpacity: 0.5
        ),
        DateEvent(
            id: 3,
            title: "しあわせの箱",
            targetDate: date(2000, 1, 9),
            isFuture: true,
            mode: .countDown,
            backgroundImageName: "iphone",
            isPinned: true
        ),
        DateEvent(
            id: 4,
            title: "赤く染まる",
            targetDate: date(2026, 12, 18),
            isFuture: true,
            mode: .countDown
        ),
        DateEvent(
            id: 5,
            title: "雪がすぎたら",
            targetDate: date(2021, 5, 20),
            isFuture: false,
            mode: .accumulate
        ),
    ]

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return Calendar.current.date(from: comps) ?? Date()
    }

    // 样例放
    static func seedIfEmpty(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<DateEvent>())) ?? 0
        guard count == 0 else { return }
        sampleEvents.forEach { context.insert($0) }
        try? context.save()
        // 新事件的编号从 6 开始
        EventIDGenerator.ensureAtLeast(6)
    }

    @MainActor
    static func previewContainer() -> ModelContainer {
        let container = try! ModelContainer(
            for: DateEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        sampleEvents.forEach { context.insert($0) }
        try? context.save()
        return container
    }
}
