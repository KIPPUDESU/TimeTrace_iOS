import SwiftUI

// 纯净海报内容
struct PosterContent: View {
    let event: DateEvent
    let days: Int
    // 是否显示实时时分秒；编辑器里的全屏预览不显示，跟安卓一致
    var showsTime: Bool = true
    // 定格事件：展开控件栏时切换为「定格自 + 定格时刻」；保存图片保持默认 false
    var revealsFrozenMeta: Bool = false
    // 缩放系数：详情页全屏是 1，编辑器小尺寸预览按比例缩小字号
    var scale: CGFloat = 1.0
    // 首次进入时的一次性文字滑入量
    var firstSlideX: CGFloat = 0
    // 编辑预览传入后台裁好的图片
    var preparedBackground: UIImage? = nil

    // 横移距离
    @Environment(\.tabSlideOffset) private var slideOffset

    private var showFrozenDetails: Bool { event.isStopped && revealsFrozenMeta }

    var body: some View {
        ZStack {
            // 只有文字滑动
            ZStack {
                // 背景图满屏
                EventBackgroundView(event: event, preparedImage: preparedBackground)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                // 黑的遮罩
                Color.black.opacity(event.maskOpacity)
            }

            VStack(spacing: 0) {
                Spacer()
                titleText
                    .offset(x: firstSlideX)
                Spacer().frame(height: 16 * scale)
                daysText
                metaPrimaryLine
                    .offset(x: firstSlideX)
                if showsTime {
                    Spacer().frame(height: 8 * scale)
                    metaSecondaryLine
                        .offset(x: firstSlideX)
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .offset(x: slideOffset)
            .animation(.easeInOut(duration: 0.28), value: showFrozenDetails)
        }
        // 海报铺满父容器，图片不会按自然尺寸撑开布局
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    // 这个标题限宽换行，还有/已经 的前缀必须尾随其后
    // 不再按字数硬切：一个字一行几个的切法只适合汉字，
    // 英文那样切会变成一行几个字母。限定成「一行放得下 9 个汉字」的宽度，
    // 汉字还是 9 个字一行，英文自己按单词换行，最多四行，多的部分系统补省略号
    private var titleText: some View {
        let prefix = event.isStopped
            ? L("label_frozen")
            : L(event.isFuture ? "label_until" : "label_since")

        // 用富文本拼：标题白色、前缀半透明白，避开已弃用的 Text 加法
        var base = AttributeContainer()
        base.font = .system(size: 30 * scale, weight: .light)
        base.kern = 4.0 * scale

        var titleAttr = AttributedString(event.title)
        titleAttr.mergeAttributes(base)
        titleAttr.foregroundColor = .white

        var prefixAttr = AttributedString(" " + prefix)
        prefixAttr.mergeAttributes(base)
        prefixAttr.foregroundColor = .white.opacity(0.7)

        return Text(titleAttr + prefixAttr)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .frame(maxWidth: titleLineWidth)
    }

    // 一行 9 个汉字要的宽度（字号 30 加字距 4）
    private var titleLineWidth: CGFloat { 9 * 34 * scale }

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

    @ViewBuilder
    private var metaPrimaryLine: some View {
        Text(showFrozenDetails ? frozenSinceText : targetDateText)
            .font(.system(size: 17 * scale))
            .foregroundStyle(.white.opacity(showFrozenDetails ? 0.8 : 0.6))
            .tracking(2 * scale)
            .contentTransition(.opacity)
            .id(showFrozenDetails ? "frozen-date" : "target-date")
    }

    @ViewBuilder
    private var metaSecondaryLine: some View {
        Group {
            if showFrozenDetails {
                Text(TimeUtils.clockTime(event.stoppedAt ?? event.targetDate))
                    .font(.system(size: 17 * scale))
                    .tracking(4 * scale)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                timeText
            }
        }
        .contentTransition(.opacity)
        .id(showFrozenDetails ? "frozen-clock" : "relative-time")
    }

    private var targetDateText: String {
        "\(L(event.isFuture ? "label_from" : "label_since_date")) \(TimeUtils.shortDate(event.targetDate))"
    }

    private var frozenSinceText: String {
        "\(L("label_frozen_since")) \(TimeUtils.shortDate(event.stoppedAt ?? event.targetDate))"
    }

    // 时分秒desu
    private var timeText: some View {
        Group {
            if let frozen = event.stoppedAt {
                relativeTimeLabel(now: frozen)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    relativeTimeLabel(now: context.date)
                }
            }
        }
    }

    private func relativeTimeLabel(now: Date) -> some View {
        let t = TimeUtils.detailedTime(targetDate: event.targetDate, now: now)
        return Text(String(format: "%02d:%02d:%02d", t.hours, t.minutes, t.seconds))
            .font(.system(size: 17 * scale))
            .tracking(4 * scale)
            .foregroundStyle(.white.opacity(0.8))
    }
}

// 页面变成当前页时，天数从 0 数到真实值，我好喜欢这个动画
struct EventPosterView: View {
    let event: DateEvent
    var isCurrentPage: Bool = false
    // 详情页每次重新出现清零
    var replayToken: Int = 0
    var firstSlideX: CGFloat = 0
    var revealsFrozenMeta: Bool = false
    // 天数跳动动画开
    @AppStorage(AppPreferenceKeys.dayCountAnimation) private var dayCountAnimOn = true

    @State private var animatedDays = 0

    // 天数直接跳到已有的
    var body: some View {
        PosterContent(
            event: event,
            days: animatedDays,
            revealsFrozenMeta: revealsFrozenMeta,
            firstSlideX: firstSlideX
        )
            .onAppear { if isCurrentPage { showDays() } }
            .onChange(of: isCurrentPage) { _, current in
                if current { showDays() } else { animatedDays = 0 }
            }
            .onChange(of: replayToken) { _, _ in
                if isCurrentPage { showDays() }
            }
    }
    
    private func showDays() {
        let target = TimeUtils.daysBetween(targetDate: event.targetDate, now: event.referenceNow)
        if dayCountAnimOn {
            animatedDays = 0
            withAnimation(.easeOut(duration: 0.8)) { animatedDays = target }
        } else {
            animatedDays = target
        }
    }
}

#Preview("海报预览") {
    PosterContent(event: PresetData.sampleEvents[0], days: 42)
        .frame(width: 393, height: 852)
        // 预览默认在安全区内，这里忽略安全区让背景顶到最顶
        .ignoresSafeArea()
}
