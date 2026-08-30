import Foundation
import ZIPFoundation

// 数据备份与恢复

// 安卓版互通

enum BackupError: LocalizedError {
    case invalidArchive

    var errorDescription: String? { L("backup_invalid") }
}

enum BackupManager {
    // 把全部记录打包
    static func exportArchive(events: [DateEvent]) throws -> Data {
        let files = FileManager.default
        let work = files.temporaryDirectory.appendingPathComponent("backup-export-\(UUID().uuidString)")
        let backgrounds = work.appendingPathComponent("backgrounds")
        try files.createDirectory(at: backgrounds, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: work) }

        var payload: [[String: Any]] = []
        for event in events {
            // 格式格式格式不准改！！！（恼
            var item: [String: Any] = [
                "id": event.id,
                "title": event.title,
                "targetDate": Int64(event.targetDate.timeIntervalSince1970 * 1000),
                "isFuture": event.isFuture,
                "isLunar": event.isLunar,
                "mode": event.mode.backupValue,
                "isPinned": event.isPinned,
                "maskOpacity": event.maskOpacity,
            ]
            // 背景图原件打包 查素材名 磁盘上没有文件就跳过
            if let name = event.backgroundImageName {
                let fileName = (name as NSString).lastPathComponent
                let source = ImageUtils.backgroundsDirectory.appendingPathComponent(fileName)
                if files.fileExists(atPath: source.path) {
                    try? files.copyItem(at: source, to: backgrounds.appendingPathComponent(fileName))
                    item["backgroundFile"] = fileName
                }
            }
            payload.append(item)
        }

        let json = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        try json.write(to: work.appendingPathComponent("events.json"))

        let zipURL = files.temporaryDirectory.appendingPathComponent("backup-\(UUID().uuidString).zip")
        defer { try? files.removeItem(at: zipURL) }
        // 不保留最外层目录，压缩包里第一层就是 events.json 和 backgrounds
        try files.zipItem(at: work, to: zipURL, shouldKeepParent: false, compressionMethod: .deflate)
        return try Data(contentsOf: zipURL)
    }

    // 读出记录，把背景图搬进本机目录
    // 只负责解析和搬图，写不写进库交给调用方决定
    static func importArchive(from url: URL) throws -> [DateEvent] {
        let files = FileManager.default
        let work = files.temporaryDirectory.appendingPathComponent("backup-import-\(UUID().uuidString)")
        defer { try? files.removeItem(at: work) }
        try files.unzipItem(at: url, to: work)

        let eventsFile = work.appendingPathComponent("events.json")
        guard files.fileExists(atPath: eventsFile.path) else { throw BackupError.invalidArchive }

        // 背景图先搬
        let incoming = work.appendingPathComponent("backgrounds")
        if let picked = try? files.contentsOfDirectory(at: incoming, includingPropertiesForKeys: nil) {
            for file in picked {
                let target = ImageUtils.backgroundsDirectory.appendingPathComponent(file.lastPathComponent)
                try? files.removeItem(at: target)
                try? files.copyItem(at: file, to: target)
            }
        }

        let raw = try Data(contentsOf: eventsFile)
        guard let array = try JSONSerialization.jsonObject(with: raw) as? [[String: Any]] else {
            throw BackupError.invalidArchive
        }
        return array.compactMap(makeEvent)
    }

    // 缺的字段按安卓那边的默认值
    private static func makeEvent(from item: [String: Any]) -> DateEvent? {
        guard let title = item["title"] as? String,
              let millis = item["targetDate"] as? NSNumber else { return nil }
        return DateEvent(
            id: (item["id"] as? NSNumber)?.int64Value ?? 0,
            title: title,
            targetDate: Date(timeIntervalSince1970: millis.doubleValue / 1000),
            isFuture: item["isFuture"] as? Bool ?? false,
            isLunar: item["isLunar"] as? Bool ?? false,
            mode: DisplayMode(backupValue: item["mode"] as? String ?? ""),
            backgroundImageName: item["backgroundFile"] as? String,
            isPinned: item["isPinned"] as? Bool ?? false,
            maskOpacity: (item["maskOpacity"] as? NSNumber)?.doubleValue ?? 0.3
        )
    }
}

// 备份文件里倒数和累计的写法
private extension DisplayMode {
    var backupValue: String {
        switch self {
        case .countDown: return "COUNT_DOWN"
        case .accumulate: return "ACCUMULATE"
        }
    }

    init(backupValue: String) {
        self = backupValue == "ACCUMULATE" ? .accumulate : .countDown
    }
}
