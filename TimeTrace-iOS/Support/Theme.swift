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
