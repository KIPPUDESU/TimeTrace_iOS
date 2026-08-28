import SwiftUI
import UIKit

// 这个地方放主题颜色
extension Color {
    /// 16 进制 RGB 初始化
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// 浅深色自适应语义色（对应安卓 Color.kt 的 Light/Dark）
    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// 语义色彩
enum TimeTracePalette {
    static let background       = Color.adaptive(light: 0xF2F3F5, dark: 0x121212)
    static let surface          = Color.adaptive(light: 0xFFFFFF, dark: 0x1E1E1E)
    static let primary          = Color.adaptive(light: 0x1A1A1A, dark: 0xE0E0E0)
    static let onPrimary        = Color.adaptive(light: 0xFFFFFF, dark: 0x0F0F0F)
    static let secondary        = Color.adaptive(light: 0x757575, dark: 0x9E9E9E)
    static let onSurface        = Color.adaptive(light: 0x1A1A1A, dark: 0xE0E0E0)
    static let surfaceVariant   = Color.adaptive(light: 0xE1E2E4, dark: 0x44474E)
    static let onSurfaceVariant = Color.adaptive(light: 0x44474E, dark: 0xC4C6D0)
    static let outline          = Color.adaptive(light: 0x74777F, dark: 0x8E9099)
    static let error            = Color.adaptive(light: 0xB3261E, dark: 0xF2B8B5)
}

// 日夜模式三档，跟安卓的 ThemeMode 对齐
enum ThemeMode: String, CaseIterable, Identifiable {
    case system   // 跟随系统
    case light    // 浅色模式
    case dark     // 深色模式

    var id: String { rawValue }

    // 选项显示名
    var label: String {
        switch self {
        case .system: return String(localized: "follow_system")
        case .light: return String(localized: "light_mode")
        case .dark: return String(localized: "dark_mode")
        }
    }
}

// 语言模式四档，跟安卓的 LanguageMode 对齐，目前先只记住选择
enum LanguageMode: String, CaseIterable, Identifiable {
    case system     // 跟随系统
    case chinese    // 简体中文
    case english    // English
    case japanese   // 日本語

    var id: String { rawValue }

    // 对应的 .lproj 文件夹名，跟随系统时返回 nil
    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .chinese: return "zh-Hans"
        case .english: return "en"
        case .japanese: return "ja"
        }
    }

    // 选项显示名
    var label: String {
        switch self {
        case .system: return String(localized: "follow_system")
        case .chinese: return String(localized: "language_chinese")
        case .english: return String(localized: "language_english")
        case .japanese: return String(localized: "language_japanese")
        }
    }
}

// 设置偏好在系统里的存储键，设置页和根视图共用
enum AppPreferenceKeys {
    static let themeMode = "themeMode"
    static let languageMode = "languageMode"
}
