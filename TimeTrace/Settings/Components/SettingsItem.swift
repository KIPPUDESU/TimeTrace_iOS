import SwiftUI

// 主色图标、标题、副标题、右箭头
struct SettingsItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 主色图标，对应安卓条目左边的图标
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(TimeTracePalette.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(TimeTracePalette.onSurface)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(TimeTracePalette.onSurfaceVariant)
                    }
                }

                Spacer()

                // 右箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TimeTracePalette.onSurfaceVariant.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("设置条目") {
    VStack(spacing: 12) {
        SettingsItem(icon: "moon.fill", title: "日夜模式", subtitle: "跟随系统") {}
        SettingsItem(icon: "globe", title: "语言选择", subtitle: "简体中文") {}
        SettingsItem(icon: "externaldrive.badge.checkmark", title: "数据备份与恢复", subtitle: "本地导入/导出") {}
    }
    .padding()
    .background(TimeTracePalette.background)
}

#Preview("设置条目深色模式") {
    VStack(spacing: 12) {
        SettingsItem(icon: "moon.fill", title: "日夜模式", subtitle: "跟随系统") {}
        SettingsItem(icon: "globe", title: "语言选择", subtitle: "简体中文") {}
    }
    .padding()
    .background(TimeTracePalette.background)
    .preferredColorScheme(.dark)
}
