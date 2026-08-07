import SwiftUI

// 置顶卡片：16:9 大卡
// 背景图渐变遮罩和置顶标签
struct PinnedEventCard: View {
    let event: DateEvent
    var onClick: () -> Void = {}

    var body: some View {
        Button(action: onClick) {
            // 卡片尺寸 16:9
            // 图片居中裁切（前端里这就叫 over-hidden）
            GeometryReader { proxy in
                ZStack(alignment: .bottomLeading) {
                    // 图片层铺满卡片，超出部分裁剪
                    EventBackgroundView(event: event)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    // 垂直渐变遮罩
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(event.maskOpacity)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    PinnedCardContent(event: event)
                        .padding(24)

                    // 置顶标签
                    Text("置顶")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(16)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// 按标题视觉宽度选择三档排版
private struct PinnedCardContent: View {
    let event: DateEvent

    var body: some View {
        let width = TimeTextUtils.visualWidth(of: event.title)
        let days = TimeUtils.daysBetween(targetDate: event.targetDate)
        Group {
            if width > 15 {
                PinnedWideLayout(event: event)
            } else if width > 5.5
                // 天数太长升级排版，四位数天数配上不算短的标题
                || (width >= 4 && days >= 1000)
                // 天数超长到五位数时，标题短也升级排版
                || (width >= 3 && days >= 10000) {
                PinnedTallLayout(event: event)
            } else {
                PinnedShortLayout(event: event)
            }
        }
    }
}

// 最多 4 行，最后一行强淡出
private struct PinnedWideLayout: View {
    let event: DateEvent

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // 只淡最后一行右侧
            OverflowFadeTitle(
                text: TimeTextUtils.forceCharacterWrap(event.title),
                font: .system(size: 26, weight: .bold),
                lineLimit: 4,
                lineSpacing: 6,
            )
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 8)
            // 标题容器
            .frame(maxWidth: 134)
            Spacer(minLength: 0)

            PinnedDaysBlock(event: event, daysSize: 50)
        }
    }
}

// 标题在天数上方
private struct PinnedTallLayout: View {
    let event: DateEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题一行文字，顶到卡片右边界渐隐
            OverflowFadeTitle(
                text: event.title,
                font: .system(size: 32, weight: .bold),
                lineLimit: 1,
            )
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 8)
            // 标题上移
            .offset(y: -4)

            // 竖排时日期在天数左下，天数块靠左对齐
            PinnedDaysBlock(
                event: event,
                daysSize: 54,
                alignment: .leading,
                // 天数数字单独上移
                daysOffset: -8,
                // 日期
                dateOffset: -6,
                // 日期字号调大
                dateSize: 14
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 短标题横排
private struct PinnedShortLayout: View {
    let event: DateEvent

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 8)
                Text(TimeUtils.shortDate(event.targetDate))
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    // 日期和标题左边对齐
                    .offset(x: 4, y: -6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PinnedDaysBlock(
                event: event,
                // 天数到五位缩小一号，避免数字太宽挤占标题
                daysSize: TimeUtils.daysBetween(targetDate: event.targetDate) >= 10000 ? 50 : 54,
                showsDate: false
            )
   
        }
    }
}

// 天数 单位 日期
private struct PinnedDaysBlock: View {
    let event: DateEvent
    var daysSize: CGFloat
    // 日期下显不显示
    var showsDate: Bool = true
    // 天数块靠左还是靠右
    var alignment: HorizontalAlignment = .trailing
    // 天数数字单独上下调
    var daysOffset: CGFloat = 0
    // 日期单独上下调
    var dateOffset: CGFloat = 0
    // 日期字号
    var dateSize: CGFloat = 14

    var body: some View {
        VStack(alignment: alignment, spacing: -2) {
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(TimeUtils.daysBetween(targetDate: event.targetDate))")
                    .font(.system(size: daysSize, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 12)
                    .contentTransition(.numericText())
                Text("天")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 10)
            }
            .offset(y: daysOffset)
            // 判定
            if showsDate {
                Text(TimeUtils.shortDate(event.targetDate))
                    .font(.system(size: dateSize))
                    .foregroundStyle(.white.opacity(0.7))
                    .offset(y: dateOffset)
            }
        }
    }
}

// 背景图
// 有背景图时渲染 bundle 内图片，无背景图时浅灰
struct EventBackgroundView: View {
    let event: DateEvent

    var body: some View {
        Group {
            if let name = event.backgroundImageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                TimeTracePalette.surfaceVariant
            }
        }
    }
}

// 普通卡片，按标题视觉宽度分两种排版
struct NormalEventCard: View {
    let event: DateEvent
    var onClick: () -> Void = {}

    private var isCollision: Bool {
        let width = TimeTextUtils.visualWidth(of: event.title)
        let days = TimeUtils.daysBetween(targetDate: event.targetDate)
        return event.title.count > 8 || width > 15 || (width >= 10 && days >= 1000)
    }

    var body: some View {
        Button(action: onClick) {
            Group {
                if isCollision {
                    NormalCollapsedLayout(event: event)
                } else {
                    NormalStandardLayout(event: event)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isCollision ? 130 : 100)
            .background(TimeTracePalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// 标题在上，日期左下、天数右下
private struct NormalCollapsedLayout: View {
    let event: DateEvent

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 依旧是渐隐
            OverflowFadeTitle(
                text: event.title,
                font: .title2.weight(.bold),
                lineLimit: 1,
            )
            .foregroundStyle(TimeTracePalette.onSurface)

            Text("\(prefix) \(TimeUtils.relativeDescription(targetDate: event.targetDate))")
                .font(.body)
                .foregroundStyle(TimeTracePalette.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, 6)

            HStack(alignment: .bottom, spacing: 2) {
                Text("\(TimeUtils.daysBetween(targetDate: event.targetDate))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(TimeTracePalette.primary)
                Text("天")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TimeTracePalette.secondary)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var prefix: String { event.isFuture ? "还有" : "已经" }
}

/// 标准横排
private struct NormalStandardLayout: View {
    let event: DateEvent

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                // 隐
                OverflowFadeTitle(
                    text: event.title,
                    font: .title2.weight(.bold),
                    lineLimit: 1,
                )
                .foregroundStyle(TimeTracePalette.onSurface)
                Text("\(prefix) \(TimeUtils.relativeDescription(targetDate: event.targetDate))")
                    .font(.body)
                    .foregroundStyle(TimeTracePalette.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(TimeUtils.daysBetween(targetDate: event.targetDate))")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(TimeTracePalette.primary)
                Text("天")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TimeTracePalette.secondary)
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 24)
    }

    private var prefix: String { event.isFuture ? "还有" : "已经" }
}

#Preview("普通卡横排") {
    NormalEventCard(event: MockData.sampleEvents[3])
        .padding()
        .background(TimeTracePalette.background)
}

#Preview("普通卡堆叠") {
    NormalEventCard(event: MockData.sampleEvents[5])
        .padding()
        .background(TimeTracePalette.background)
}

#Preview("置顶卡") {
    PinnedEventCard(event: MockData.sampleEvents[0])
        .padding()
        .background(TimeTracePalette.background)
}
