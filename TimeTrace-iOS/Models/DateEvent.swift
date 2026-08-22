import Foundation
import SwiftData

// 倒数还是累计
enum DisplayMode: String, Codable, Hashable {
    case countDown   // 倒数
    case accumulate  // 累计
}

// 时间记录
@Model
final class DateEvent {
    // 内部自增编号，排序用
    var id: Int64 = 0
    var title: String = ""
    var targetDate: Date = Date()
    // 语义判断 已经 / 还有
    var isFuture: Bool = false
    var isLunar: Bool = false
    var mode: DisplayMode = DisplayMode.countDown
    // 背景图的文件路径
    var backgroundImageName: String?
    var isPinned: Bool = false
    var maskOpacity: Double = 0.3
    // 手动排序用（现在还没有哦 ^ ^）
    var position: Int = 0

    init(
        id: Int64 = 0,
        title: String = "",
        targetDate: Date = Date(),
        isFuture: Bool = false,
        isLunar: Bool = false,
        mode: DisplayMode = .countDown,
        backgroundImageName: String? = nil,
        isPinned: Bool = false,
        maskOpacity: Double = 0.3,
        position: Int = 0
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.isFuture = isFuture
        self.isLunar = isLunar
        self.mode = mode
        self.backgroundImageName = backgroundImageName
        self.isPinned = isPinned
        self.maskOpacity = maskOpacity
        self.position = position
    }
}

// SwiftUI 的 sheet、全屏页、删除确认框都要用 Identifiable，声明的 id 正好是 Int64
extension DateEvent: Identifiable {}

// 给新事件发不重复的自增编号
enum EventIDGenerator {
    private static let key = "EventIDGenerator.next"

    // 拿下一个编号
    static func next() -> Int64 {
        let next = (UserDefaults.standard.object(forKey: key) as? Int64) ?? 1
        UserDefaults.standard.set(next + 1, forKey: key)
        return next
    }

    // 样例占用了前几个编号时，把起点抬高，避免和新事件撞号
    static func ensureAtLeast(_ minimum: Int64) {
        let current = (UserDefaults.standard.object(forKey: key) as? Int64) ?? 1
        if current < minimum {
            UserDefaults.standard.set(minimum, forKey: key)
        }
    }
}
