import SwiftUI

// 置顶卡片：16:9 大卡，背景图 + 渐变遮罩 + 置顶标签（对应 `PinnedEventCard.kt`）
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

                    // 垂直渐变遮罩：transparent → black·maskOpacity
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(event.maskOpacity)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    PinnedCardContent(event: event)
                        .padding(24)

                    // 置顶标签
                    Text("置顶")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

/// 按标题视觉宽度选择三档排版（对应 `PinnedEventCard.kt` 的 if/else 分档）
private struct PinnedCardContent: View {
    let event: DateEvent

    var body: some View {
        let width = TimeTextUtils.visualWidth(of: event.title)
        Group {
            if width > 15 {
                PinnedWideLayout(event: event)
            } else if width > 5.5 || (width >= 4 && TimeUtils.daysBetween(targetDate: event.targetDate) >= 1000) {
                PinnedTallLayout(event: event)
            } else {
                PinnedShortLayout(event: event)
            }
        }
    }
}

/// 类型 3：超宽标题，最多 4 行、最后一行强淡出
private struct PinnedWideLayout: View {
    let event: DateEvent

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            Text(TimeTextUtils.forceCharacterWrap(event.title))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .lineSpacing(6)             // 近似 lineHeight 28sp（22sp 字号）
                .lineLimit(4)
                .shadow(color: .black.opacity(0.5), radius: 8)
                .fadeLastLineEdge(fadeWidth: 48, lastLineHeightFraction: 0.25)
                .frame(maxWidth: .infinity, alignment: .leading)

            PinnedDaysBlock(event: event, daysSize: 48)
        }
    }
}

/// 类型 2：标题在天数上方（竖排）
private struct PinnedTallLayout: View {
    let event: DateEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.5), radius: 8)
                .fadeRightEdge(fadeWidth: 48)

            PinnedDaysBlock(event: event, daysSize: 48)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 类型 1：短标题横排（标题 + 日期在左，天数在右）
private struct PinnedShortLayout: View {
    let event: DateEvent

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 8)
                Text(TimeUtils.shortDate(event.targetDate))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PinnedDaysBlock(event: event, daysSize: 48)
        }
    }
}

/// 天数 + 单位 + 日期（右下角块）
private struct PinnedDaysBlock: View {
    let event: DateEvent
    var daysSize: CGFloat

    var body: some View {
        VStack(alignment: .trailing, spacing: -2) {
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(TimeUtils.daysBetween(targetDate: event.targetDate))")
                    .font(.system(size: daysSize, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 12)
                Text("天")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 10)
            }
            Text(TimeUtils.shortDate(event.targetDate))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

/// 背景图（对应 Android `AsyncImage` / surfaceVariant 兜底）
/// 有背景图时渲染 bundle 内图片；无背景图时沿用 Android 的 surfaceVariant 兜底。
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

// MARK: - 普通卡片

/// 普通卡片：按标题视觉宽度分两种排版（对应 `NormalEventCard.kt`）
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

/// 堆叠排版（长标题）：标题在上，描述左下、天数右下
private struct NormalCollapsedLayout: View {
    let event: DateEvent

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(event.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(TimeTracePalette.onSurface)
                .lineLimit(1)
                .fadeRightEdge(fadeWidth: 48)
                .frame(maxWidth: .infinity, alignment: .topLeading)

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

/// 标准横排（短标题）：标题 + 描述在左，天数在右
private struct NormalStandardLayout: View {
    let event: DateEvent

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TimeTracePalette.onSurface)
                    .lineLimit(1)
                    .fadeRightEdge(fadeWidth: 48)
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

// MARK: - Previews

#Preview("普通卡 · 横排") {
    NormalEventCard(event: MockData.sampleEvents[3])
        .padding()
        .background(TimeTracePalette.background)
}

#Preview("普通卡 · 堆叠") {
    NormalEventCard(event: MockData.sampleEvents[5])
        .padding()
        .background(TimeTracePalette.background)
}

#Preview("置顶卡") {
    PinnedEventCard(event: MockData.sampleEvents[0])
        .padding()
        .background(TimeTracePalette.background)
}
