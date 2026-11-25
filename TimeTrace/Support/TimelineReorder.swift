import SwiftData

enum TimelineReorder {
    static func persistOrder(
        pinned: [DateEvent],
        normal: [DateEvent],
        in modelContext: ModelContext
    ) {
        for (index, event) in (pinned + normal).enumerated() where event.position != index {
            event.position = index
        }
        try? modelContext.save()
    }
}
