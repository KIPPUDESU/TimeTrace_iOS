import SwiftUI

// 纯净海报内容
struct PosterContent: View {
    let event: DateEvent
    let days: Int
    // 是否显示实时时分秒；编辑器里的全屏预览不显示，跟安卓一致
    var showsTime: Bool = true
    // 缩放系数：详情页全屏是 1，编辑器小尺寸预览按比例缩小字号
    var scale: CGFloat = 1.0

    // 横移距离
    @Environment(\.tabSlideOffset) private var slideOffset

    var body: some View {
        ZStack {
            // 只有文字滑动
            ZStack {
                // 背景图满屏
                EventBackgroundView(event: event)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                // 黑的遮罩
                Color.black.opacity(event.maskOpacity)
            }

            VStack(spacing: 0) {
                Spacer()
                titleText
                Spacer().frame(height: 16 * scale)
                daysText
                dateLine
                if showsTime {
                    Spacer().frame(height: 8 * scale)
                    timeText
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .offset(x: slideOffset)
        }
        // 海报铺满父容器，图片不会按自然尺寸撑开布局
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    // 这个标题每 9 字换行，还有/已经 的前缀必须尾随其后
    private var titleText: some View {
        let prefix = L(event.isFuture ? "label_until" : "label_since")
        let displayTitle = event.title.count > 35 ? String(event.title.prefix(32)) + "..." : event.title
        let chars = Array(displayTitle)
        let chunks = stride(from: 0, to: chars.count, by: 9)
            .map { String(chars[$0..<min($0 + 9, chars.count)]) }

        // 用富文本拼：标题白色、前缀半透明白，避开已弃用的 Text 加法
        var base = AttributeContainer()
        base.font = .system(size: 30 * scale, weight: .light)
        base.kern = 4.0 * scale

        var titleAttr = AttributedString(chunks.joined(separator: "\n"))
        titleAttr.mergeAttributes(base)
        titleAttr.foregroundColor = .white

        var prefixAttr = AttributedString(" " + prefix)
        prefixAttr.mergeAttributes(base)
        prefixAttr.foregroundColor = .white.opacity(0.7)

        return Text(titleAttr + prefixAttr)
            .multilineTextAlignment(.center)
    }

    // 天数按位数自适应字号，多就小点
    private var daysText: some View {
        Text("\(days)")
            .font(.system(size: daysFontSize, weight: .bold))
            .foregroundStyle(.white)
            .contentTransition(.numericText())
    }

    private var daysFontSize: CGFloat {
        switch String(days).count {
        case 8...: return 60 * scale
        case 7: return 72 * scale
        case 6: return 88 * scale
        case 5: return 100 * scale
        default: return 120 * scale
        }
    }

    // 日期
    private var dateLine: some View {
        Text("\(L(event.isFuture ? "label_from" : "label_since_date")) \(TimeUtils.shortDate(event.targetDate))")
            .font(.system(size: 17 * scale))
            .foregroundStyle(.white.opacity(0.6))
            .tracking(2 * scale)
    }

    // 时分秒desu
    private var timeText: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let t = TimeUtils.detailedTime(targetDate: event.targetDate, now: context.date)
            Text(String(format: "%02d:%02d:%02d", t.hours, t.minutes, t.seconds))
                .font(.system(size: 17 * scale))
                .tracking(4 * scale)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// 页面变成当前页时，天数从 0 数到真实值，我好喜欢这个动画
struct EventPosterView: View {
    let event: DateEvent
    var isCurrentPage: Bool = false
    // 恢复天数不从 0 数
    var countUp: Bool = true

    @State private var animatedDays = 0

    var body: some View {
        PosterContent(event: event, days: animatedDays)
            // 首次就是当前页时直接播动画
            .onAppear {
                if isCurrentPage { countUp ? animateToFinal() : jumpToFinal() }
            }
            // 每次滑入变成当前页都重播一遍，离页归零
            .onChange(of: isCurrentPage) { _, current in
                if current { countUp ? animateToFinal() : jumpToFinal() } else { animatedDays = 0 }
            }
    }

    private func jumpToFinal() {
        animatedDays = TimeUtils.daysBetween(targetDate: event.targetDate)
    }

    private func animateToFinal() {
        let target = TimeUtils.daysBetween(targetDate: event.targetDate)
        withAnimation(.easeOut(duration: 0.8)) { animatedDays = target }
    }
}

#Preview("海报预览") {
    PosterContent(event: MockData.sampleEvents[0], days: 42)
        .frame(width: 393, height: 852)
        // 预览默认在安全区内，这里忽略安全区让背景顶到最顶
        .ignoresSafeArea()
}
