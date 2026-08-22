import SwiftUI

// 玻璃选择面板选项
struct GlassOption: Identifiable {
    let id: String
    let icon: String
    let title: String
    // 图标区要显示的单个文字（比如「あ」）；给了它就不用 SF Symbol
    var iconText: String? = nil
}

struct GlassOptionRow: View {
    let option: GlassOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 左侧图标
                Group {
                    if let text = option.iconText {
                        Text(text)
                            .font(.system(size: 18, weight: .semibold))
                    } else {
                        Image(systemName: option.icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(width: 26)

                // 选项名
                Text(option.title)
                    .font(.body.weight(isSelected ? .bold : .regular))

                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TimeTracePalette.primary)
                }
            }
            .foregroundStyle(TimeTracePalette.onSurface)
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            // 选中行垫一层柔和的浅灰半透明
            .background(
                isSelected ? TimeTracePalette.surfaceVariant.opacity(0.6) : Color.clear,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("选项行") {
    VStack(spacing: 8) {
        GlassOptionRow(option: GlassOption(id: "dark", icon: "moon.fill", title: "深色模式"), isSelected: true) {}
        GlassOptionRow(option: GlassOption(id: "light", icon: "sun.max.fill", title: "浅色模式"), isSelected: false) {}
    }
    .padding()
    .background(TimeTracePalette.background)
}

#Preview("选项行深色模式") {
    VStack(spacing: 8) {
        GlassOptionRow(option: GlassOption(id: "dark", icon: "moon.fill", title: "深色模式"), isSelected: true) {}
        GlassOptionRow(option: GlassOption(id: "light", icon: "sun.max.fill", title: "浅色模式"), isSelected: false) {}
    }
    .padding()
    .background(TimeTracePalette.background)
    .preferredColorScheme(.dark)
}
