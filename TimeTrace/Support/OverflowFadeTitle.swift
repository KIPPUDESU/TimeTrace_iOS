import SwiftUI

// 标题文字的渐隐容器
// 渐隐只在文字超出“容器”范围时才出现
// 用 lineLimit 控制行数保证布局正确
struct OverflowFadeTitle: View {
    let text: String
    let font: Font
    var lineLimit: Int = 1
    var lineSpacing: CGFloat = 0
    // 渐隐起始位置
    var fadeWidth: CGFloat = 68

    @State private var containerSize: CGSize = .zero
    @State private var naturalHeight: CGFloat = 0

    var body: some View {
        Text(text)
            .font(font)
            .lineSpacing(lineSpacing)
            .lineLimit(lineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(containerMeasurer)
            .overlay(naturalMeasurer)
            .mask(fadeMask)
    }

    // 量出卡片给文字留出的范围
    private var containerMeasurer: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { containerSize = geo.size }
                .onChange(of: geo.size) { _, new in containerSize = new }
        }
    }

    // 把文字按容器宽度自然换行
    @ViewBuilder
    private var naturalMeasurer: some View {
        if containerSize.width > 0 {
            Text(text)
                .font(font)
                .lineSpacing(lineSpacing)
                .lineLimit(nil)
                .frame(width: containerSize.width, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(0)
                .allowsHitTesting(false)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { naturalHeight = geo.size.height }
                            .onChange(of: geo.size) { _, new in naturalHeight = new.height }
                    }
                )
        }
    }

    @ViewBuilder
    private var fadeMask: some View {
        // 文字被截断，渐隐
        if naturalHeight > containerSize.height + 1 {
            if lineLimit > 1 {
                lastLineMask
            } else {
                rightEdgeMask
            }
        } else {
            Color.black
        }
    }

    // 整行右侧渐隐，透明区盖住苹果原SLM的省略号省略号
    private var rightEdgeMask: some View {
        let w = containerSize.width
        let fadeStart = max(w - fadeWidth, 0)
        let fadeEnd = max(w - 52, 0)
        return LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: max(0.01, fadeStart / max(w, 1))),
                .init(color: .clear, location: max(0.02, fadeEnd / max(w, 1))),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // 只淡最后一行右侧
    private var lastLineMask: some View {
        let w = containerSize.width
        let h = containerSize.height
        let lastLineFraction = 1.0 / CGFloat(max(lineLimit, 1))
        let lastLineStart = h * (1 - lastLineFraction)
        let fadeStart = max(w - fadeWidth, 0)
        // 盖住
        let fadeEnd = max(w - 52, 0)
        return Canvas { ctx, _ in
            // 前面的行完全显示
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: lastLineStart)), with: .color(.black))
            // 最后一行左侧完全显示
            ctx.fill(
                Path(CGRect(x: 0, y: lastLineStart, width: fadeStart, height: h - lastLineStart)),
                with: .color(.black)
            )
            // 最后一行渐隐段
            ctx.fill(
                Path(CGRect(x: fadeStart, y: lastLineStart, width: fadeEnd - fadeStart, height: h - lastLineStart)),
                with: .linearGradient(
                    Gradient(colors: [.black, .clear]),
                    startPoint: CGPoint(x: fadeStart, y: 0),
                    endPoint: CGPoint(x: fadeEnd, y: 0)
                )
            )
        }
    }
}
