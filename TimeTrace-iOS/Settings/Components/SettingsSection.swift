import SwiftUI

// 主色小标题加圆角大卡片
struct SettingsSection<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TimeTracePalette.primary)
                .padding(.leading, 12)

            VStack(spacing: 0) {
                content
            }
            .background(
                TimeTracePalette.surfaceVariant.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
    }
}

#Preview("设置分组") {
    SettingsSection(title: "通用设置") {
        SettingsItem(icon: "moon.fill", title: "日夜模式", subtitle: "跟随系统") {}
    }
    .padding()
    .background(TimeTracePalette.background)
}

#Preview("设置分组深色模式") {
    SettingsSection(title: "通用设置") {
        SettingsItem(icon: "moon.fill", title: "日夜模式", subtitle: "跟随系统") {}
    }
    .padding()
    .background(TimeTracePalette.background)
    .preferredColorScheme(.dark)
}
