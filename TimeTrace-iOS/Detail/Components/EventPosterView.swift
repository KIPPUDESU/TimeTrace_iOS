import SwiftUI

// 纯净海报内容
struct PosterContent: View {
    let event: DateEvent
    let days: Int

    var body: some View {
        ZStack {
            // 背景图满屏
            EventBackgroundView(event: event)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            // 黑的遮罩
            Color.black.opacity(event.maskOpacity)

            VStack(spacing: 0) {
                Spacer()
                titleText
                Spacer().frame(height: 16)
                daysText
                dateLine
                Spacer().frame(height: 8)
                timeText
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .background(Color.black)
    }

    // 这个标题每 9 字换行，还有/已经 的前缀必须尾随其后
    private var titleText: some View {
        let prefix = event.isFuture ? "还有" : "已经"
        let displayTitle = event.title.count > 35 ? String(event.title.prefix(32)) + "..." : event.title
        let chars = Array(displayTitle)
        let chunks = stride(from: 0, to: chars.count, by: 9)
            .map { String(chars[$0..<min($0 + 9, chars.count)]) }
        return (Text(chunks.joined(separator: "\n"))
            + Text(" " + prefix).foregroundStyle(.white.opacity(0.7)))
            .font(.system(size: 24, weight: .light))
            .tracking(4)
            .foregroundStyle(.white)
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
        case 8...: return 60
        case 7: return 72
        case 6: return 88
        case 5: return 100
        default: return 120
        }
    }

    // 日期
    private var dateLine: some View {
        Text("\(event.isFuture ? "距离" : "自从") \(TimeUtils.shortDate(event.targetDate))")
            .font(.system(size: 17))
            .foregroundStyle(.white.opacity(0.6))
            .tracking(2)
    }

    // 时分秒desu
    private var timeText: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let t = TimeUtils.detailedTime(targetDate: event.targetDate, now: context.date)
            Text(String(format: "%02d:%02d:%02d", t.hours, t.minutes, t.seconds))
                .font(.system(size: 17))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// 页面变成当前页时，天数从 0 数到真实值，我好喜欢这个动画
struct EventPosterView: View {
    let event: DateEvent
    var isCurrentPage: Bool = false

    @State private var animatedDays = 0

    var body: some View {
        PosterContent(event: event, days: animatedDays)
            // 首次就是当前页时直接播动画
            .onAppear { if isCurrentPage { animateToFinal() } }
            // 每次滑入变成当前页都重播一遍，离页归零
            .onChange(of: isCurrentPage) { _, current in
                if current { animateToFinal() } else { animatedDays = 0 }
            }
    }

    private func animateToFinal() {
        let target = TimeUtils.daysBetween(targetDate: event.targetDate)
        withAnimation(.easeOut(duration: 0.8)) { animatedDays = target }
    }
}

#Preview("海报预览") {
    PosterContent(event: MockData.sampleEvents[0], days: 42)
        .frame(width: 393, height: 852)
}
