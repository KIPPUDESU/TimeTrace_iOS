import Foundation

// 系统只在 App 启动那一刻读一次 AppleLanguages
// SwiftUI 的 Text 和 String(localized:) 都不认运行时的改动，实测会慢一拍
// 所以取词一律走 L(...)，自己去选中的那份语言文件里查

// 按当前选中的语言取一句文案
func L(_ key: String) -> String {
    LanguageManager.localized(key)
}

nonisolated enum LanguageManager {
    // 当前选中语言的那份语言文件，跟随系统时是空的
    nonisolated(unsafe) private static var selectedBundle: Bundle?

    /// 切换到指定语言，传 nil 恢复跟随系统
    static func apply(_ localeIdentifier: String?) {
        guard let identifier = localeIdentifier else {
            // 跟随系统，清掉我们写进去的偏好，改用系统自己的语言
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            selectedBundle = systemBundle()
            return
        }
        // 记进系统偏好，下次启动一上来就是这个语言
        UserDefaults.standard.set([identifier], forKey: "AppleLanguages")
        selectedBundle = languageBundle(for: identifier)
    }

    // 取词，选中的语言文件里没有就退回主包
    static func localized(_ key: String) -> String {
        let bundle = selectedBundle ?? .main
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    // 找某个语言对应的语言文件夹
    private static func languageBundle(for identifier: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: identifier, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }

    // 系统当前偏好的语言对应哪份语言文件
    private static func systemBundle() -> Bundle? {
        let best = Bundle.preferredLocalizations(
            from: Bundle.main.localizations,
            forPreferences: systemPreferredLanguages
        ).first
        return best.flatMap { languageBundle(for: $0) }
    }

    // 系统真正的偏好语言顺序
    // 要绕开我们自己写进 App 域的那份，直接读系统全局的，否则读回来的是刚清掉的旧值
    private static var systemPreferredLanguages: [String] {
        let global = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        return (global?["AppleLanguages"] as? [String]) ?? Locale.preferredLanguages
    }
}
