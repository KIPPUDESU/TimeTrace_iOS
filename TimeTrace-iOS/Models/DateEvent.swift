import Foundation

// 放设定的数据函数变量
// 倒数累计（对应安卓的 `DisplayMode`）
enum DisplayMode: Hashable {
    case countDown   // 倒数
    case accumulate  // 累计
}

// 时间记录（对应安卓的 `DateEvent`，Room 表 date_events）
struct DateEvent: Identifiable, Equatable {
    var id: Int64 = 0
    var title: String
    var targetDate: Date
    var isFuture: Bool
    var isLunar: Bool = false
    var mode: DisplayMode
    var backgroundImageName: String?  // 内部存储标识；真实图片加载落地后替换为文件/相册引用
    var isPinned: Bool = false
    var maskOpacity: Double = 0.3
    var position: Int = 0
}
