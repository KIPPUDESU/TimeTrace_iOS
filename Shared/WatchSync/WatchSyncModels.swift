import Foundation

enum WatchSyncKey {
    static let eventsJSON = "eventsJSON"
    static let updatedAt = "updatedAt"
    static let requestSync = "requestSync"
    static let backgroundFileName = "backgroundFileName"
}

/// iPhone → Watch 的只读快照（不含已停止项目）
struct WatchSyncEvent: Codable, Identifiable, Hashable, Sendable {
    var id: Int64
    var title: String
    var targetDate: TimeInterval
    var isFuture: Bool
    var mode: String
    var backgroundFileName: String?
    var isPinned: Bool
    var maskOpacity: Double
    var position: Int

    var targetDateValue: Date {
        Date(timeIntervalSince1970: targetDate)
    }

    var liveIsFuture: Bool {
        targetDateValue > Date()
    }
}

enum WatchSyncCodec {
    static func encode(_ events: [WatchSyncEvent]) -> Data? {
        try? JSONEncoder().encode(events)
    }

    static func decode(_ data: Data) -> [WatchSyncEvent] {
        (try? JSONDecoder().decode([WatchSyncEvent].self, from: data)) ?? []
    }

    static func ordered(_ events: [WatchSyncEvent]) -> [WatchSyncEvent] {
        let pinned = events.filter(\.isPinned)
        let normal = events.filter { !$0.isPinned }
        let sort: (WatchSyncEvent, WatchSyncEvent) -> Bool = { a, b in
            if a.position != b.position { return a.position < b.position }
            return a.id > b.id
        }
        return pinned.sorted(by: sort) + normal.sorted(by: sort)
    }
}
