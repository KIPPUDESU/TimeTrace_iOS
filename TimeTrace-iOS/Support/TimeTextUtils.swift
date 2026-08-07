import Foundation

// 文本（对应安卓 `TextUtils`）
enum TimeTextUtils {
    // 视觉宽度中文全角 = 1.0
    static func visualWidth(of text: String) -> Double {
        text.unicodeScalars.reduce(0.0) { acc, scalar in
            acc + (scalar.isASCII ? 0.5 : 1.0)
        }
    }
    static func forceCharacterWrap(_ text: String) -> String {
        text.map { "\($0)\u{200B}" }.joined()
    }
}

// 年 / 月 / 周 / 天
struct RelativeTime {
    var years: Int = 0
    var months: Int = 0
    var weeks: Int = 0
    var days: Int = 0
}

// 时间工具
enum TimeUtils {
    // 目标日与今天之间的相对的 年 / 月 / 周 / 天
    static func relativeTime(targetDate: Date, now: Date = Date()) -> RelativeTime {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: targetDate)
        let today = calendar.startOfDay(for: now)
        let (start, end) = today <= target ? (today, target) : (target, today)

        let comps = calendar.dateComponents([.year, .month, .day], from: start, to: end)
        let remainderDays = comps.day ?? 0
        return RelativeTime(
            years: comps.year ?? 0,
            months: comps.month ?? 0,
            weeks: remainderDays / 7,
            days: remainderDays % 7
        )
    }

    // 目标日与今天相差的天数
    static func daysBetween(targetDate: Date, now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: targetDate)
        let today = calendar.startOfDay(for: now)
        return abs(calendar.dateComponents([.day], from: today, to: target).day ?? 0)
    }

    // 相对时间描述
    // 就像 2年3月1周2天 今天
    static func relativeDescription(targetDate: Date, now: Date = Date()) -> String {
        let r = relativeTime(targetDate: targetDate, now: now)
        var parts: [String] = []
        if r.years > 0 { parts.append("\(r.years)年") }
        if r.months > 0 { parts.append("\(r.months)月") }
        if r.weeks > 0 { parts.append("\(r.weeks)周") }
        if r.days > 0 { parts.append("\(r.days)天") }
        return parts.isEmpty ? "今天" : parts.joined(separator: " ")
    }

    // 本地日期文本
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    // 详情页实时时分秒，目标日为成本地午夜，算距离时分秒
    static func detailedTime(targetDate: Date, now: Date = Date()) -> (hours: Int, minutes: Int, seconds: Int) {
        let targetMidnight = Calendar.current.startOfDay(for: targetDate)
        let total = abs(Int(now.timeIntervalSince(targetMidnight)))
        let hours = total % 86400 / 3600
        let minutes = total % 3600 / 60
        let seconds = total % 60
        return (hours, minutes, seconds)
    }
}
