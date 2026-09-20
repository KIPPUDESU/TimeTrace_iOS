import Foundation
import SwiftData

// 首次启动预设与预览数据
enum PresetData {
    static var sampleEvents: [DateEvent] {
        var events = presetEvents()
        #if DEBUG
        events.append(contentsOf: debugEvents())
        #endif
        return events
    }

    private static func presetEvents(now: Date = Date()) -> [DateEvent] {
        let nextYear = gregorianCalendar.component(.year, from: now) + 1

        return [
            DateEvent(
                id: 1,
                title: L("preset_candy_founded"),
                targetDate: date(2024, 8, 5),
                isFuture: false,
                mode: .accumulate,
                backgroundImageName: "candyrect",
                isPinned: true,
                maskOpacity: 0.4,
                position: 0
            ),
            DateEvent(
                id: 2,
                title: L("preset_iphone_release"),
                targetDate: date(2007, 6, 29),
                isFuture: false,
                mode: .accumulate,
                backgroundImageName: nil,
                isPinned: false,
                maskOpacity: 0.4,
                position: 1
            ),
            DateEvent(
                id: 3,
                title: String(format: L("preset_year_title_format"), nextYear),
                targetDate: date(nextYear, 1, 1),
                isFuture: true,
                mode: .countDown,
                backgroundImageName: nil,
                isPinned: false,
                maskOpacity: 0.4,
                position: 2
            ),
        ]
    }

    #if DEBUG
    private static func debugEvents() -> [DateEvent] {
        [
            DateEvent(
                id: 4,
                title: "きみのあと",
                targetDate: date(2026, 1, 1),
                isFuture: true,
                mode: .countDown,
                backgroundImageName: "graduation",
                isPinned: true,
                maskOpacity: 0.45,
                position: 3
            ),
            DateEvent(
                id: 5,
                title: "俺を殺したいらしい",
                targetDate: date(2025, 3, 1),
                isFuture: false,
                mode: .accumulate,
                backgroundImageName: "newbg",
                isPinned: true,
                maskOpacity: 0.5,
                position: 4
            ),
            DateEvent(
                id: 6,
                title: "しあわせの箱",
                targetDate: date(2000, 1, 9),
                isFuture: true,
                mode: .countDown,
                backgroundImageName: "iphone",
                isPinned: true,
                position: 5
            ),
            DateEvent(
                id: 7,
                title: "赤く染まる",
                targetDate: date(2026, 12, 18),
                isFuture: true,
                mode: .countDown,
                position: 6
            ),
            DateEvent(
                id: 8,
                title: "雪がすぎたら",
                targetDate: date(2021, 5, 20),
                isFuture: false,
                mode: .accumulate,
                position: 7
            ),
        ]
    }
    #endif

    private static var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return gregorianCalendar.date(from: components) ?? Date()
    }

    static func seedIfEmpty(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<DateEvent>())) ?? 0
        guard count == 0 else { return }

        let events = sampleEvents
        events.forEach { context.insert($0) }
        try? context.save()
        EventIDGenerator.ensureAtLeast(Int64(events.count + 1))
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
