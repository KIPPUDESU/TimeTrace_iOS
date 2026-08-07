import SwiftUI

// 全屏遮罩右上角那个功能键
// 保存图片 / 修改标题 / 更换背景 / 调整日期
struct DetailActionSheet: View {
    var onSaveImage: () -> Void
    var onEditTitle: () -> Void
    var onChangeBackground: () -> Void
    var onAdjustDate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ActionRow(icon: "square.and.arrow.down", title: "保存图片", subtitle: "保存为不含 UI 的纯净长图") { onSaveImage() }
            divider
            ActionRow(icon: "pencil", title: "修改标题", subtitle: "重新为这一刻起个名字") { onEditTitle() }
            divider
            ActionRow(icon: "photo", title: "更换背景", subtitle: "从相册选择新的背景图") { onChangeBackground() }
            divider
            ActionRow(icon: "calendar", title: "调整日期", subtitle: "修改此事件的目标日期") { onAdjustDate() }
        }
        // 卡片本身用液态玻璃，不再套实色底
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var divider: some View {
        Rectangle()
            .fill(TimeTracePalette.outline.opacity(0.3))
            .frame(height: 0.5)
            .padding(.horizontal, 24)
    }
}

// 固定的模板
// 就是说，给一个图标，一个标题，一个描述
private struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(TimeTracePalette.primary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TimeTracePalette.onSurface)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(TimeTracePalette.onSurfaceVariant.opacity(0.7))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("动作面板") {
    DetailActionSheet(
        onSaveImage: {},
        onEditTitle: {},
        onChangeBackground: {},
        onAdjustDate: {}
    )
    .padding(.top, 200)
    .background(Color.black)
}
