import SwiftUI

// 选择卡片/
struct GlassCenterPicker: View {
    let title: String
    let options: [GlassOption]
    let selectedID: String
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    // 控制出现动画的开关
    @State private var appeared = false

    var body: some View {
        ZStack {
            // 遮罩
            Color.black.opacity(appeared ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // 玻璃卡片
            VStack(spacing: 0) {
                // 顶部标题
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TimeTracePalette.onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                // 标题和选项之间的细线
//                Rectangle()
//                    .fill(TimeTracePalette.outline.opacity(0.3))
//                    .frame(height: 0.5)
//                    .padding(.horizontal, 16)

                // 选项列表
                VStack(spacing: 8) {
                    ForEach(options) { option in
                        GlassOptionRow(
                            option: option,
                            isSelected: option.id == selectedID
                        ) {
                            onSelect(option.id)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .frame(width: 320)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            // 中心扩张
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

#Preview("居中玻璃卡片") {
    ZStack {
        TimeTracePalette.background
        GlassCenterPicker(
            title: "日夜模式",
            options: [
                GlassOption(id: "system", icon: "circle.lefthalf.filled", title: "跟随系统"),
                GlassOption(id: "light", icon: "sun.max.fill", title: "浅色模式"),
                GlassOption(id: "dark", icon: "moon.fill", title: "深色模式"),
            ],
            selectedID: "system",
            onSelect: { _ in },
            onDismiss: {}
        )
    }
}

#Preview("居中玻璃卡片深色模式") {
    ZStack {
        TimeTracePalette.background
        GlassCenterPicker(
            title: "日夜模式",
            options: [
                GlassOption(id: "system", icon: "circle.lefthalf.filled", title: "跟随系统"),
                GlassOption(id: "light", icon: "sun.max.fill", title: "浅色模式"),
                GlassOption(id: "dark", icon: "moon.fill", title: "深色模式"),
            ],
            selectedID: "dark",
            onSelect: { _ in },
            onDismiss: {}
        )
    }
    .preferredColorScheme(.dark)
}
