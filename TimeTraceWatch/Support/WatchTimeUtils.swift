import Foundation

enum WatchTimeUtils {
    static func daysBetween(targetDate: Date, now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: targetDate)
        let today = calendar.startOfDay(for: now)
        return abs(calendar.dateComponents([.day], from: today, to: target).day ?? 0)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    static func detailedTime(targetDate: Date, now: Date = Date()) -> (hours: Int, minutes: Int, seconds: Int) {
        let targetMidnight = Calendar.current.startOfDay(for: targetDate)
        let total = abs(Int(now.timeIntervalSince(targetMidnight)))
        let hours = total % 86400 / 3600
        let minutes = total % 3600 / 60
        let seconds = total % 60
        return (hours, minutes, seconds)
    }

    static func clockTime(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return String(
            format: "%02d:%02d:%02d",
            parts.hour ?? 0,
            parts.minute ?? 0,
            parts.second ?? 0
        )
    }
}

func WL(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
