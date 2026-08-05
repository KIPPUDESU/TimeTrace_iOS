import SwiftUI

// 文本右侧边缘淡出（对应安卓 `fadeRightEdge`）
extension View {
    func fadeRightEdge(fadeWidth: CGFloat = 48) -> some View {
        self.mask {
            GeometryReader { geo in
                let w = geo.size.width
                let fadeStart = max(0, w - fadeWidth)
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: max(0.01, fadeStart / max(w, 1))),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }

    // 只有多行文本最后一行应用右侧淡出
    func fadeLastLineEdge(fadeWidth: CGFloat = 48, lastLineHeightFraction: CGFloat = 0.25) -> some View {
        self.mask {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let fadeStartX = max(0, w - fadeWidth)
                let lastLineStart = h * (1 - lastLineHeightFraction)
                Canvas { ctx, _ in
                    // 顶部保持 100%
                    ctx.fill(
                        Path(CGRect(x: 0, y: 0, width: w, height: lastLineStart)),
                        with: .color(.black)
                    )
                    // 最后一行左段保持 100%
                    ctx.fill(
                        Path(CGRect(x: 0, y: lastLineStart, width: fadeStartX, height: h - lastLineStart)),
                        with: .color(.black)
                    )
                    // 最后一行右段淡出
                    ctx.fill(
                        Path(CGRect(x: fadeStartX, y: lastLineStart, width: w - fadeStartX, height: h - lastLineStart)),
                        with: .linearGradient(
                            Gradient(colors: [.black, .clear]),
                            startPoint: CGPoint(x: fadeStartX, y: 0),
                            endPoint: CGPoint(x: w, y: 0)
                        )
                    )
                }
            }
        }
    }
}
