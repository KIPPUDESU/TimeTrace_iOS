import SwiftUI

struct WatchPosterView: View {
    let event: WatchSyncEvent
    var backgroundRevision: Int = 0
    var revealsFrozenMeta: Bool = false

    private var targetDate: Date { event.targetDateValue }
    private var isFuture: Bool { event.liveIsFuture }
    private var days: Int {
        WatchTimeUtils.daysBetween(targetDate: targetDate, now: event.referenceNow)
    }

    private var showFrozenDetails: Bool { event.isStopped && revealsFrozenMeta }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let scale = layoutScale(for: size)

            ZStack {
                backgroundImage(size: size)
                Color.black.opacity(min(max(event.maskOpacity, 0.2), 0.5))
                readabilityScrim

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    titleText(scale: scale)

                    daysBlock(scale: scale)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6 * scale)

                    Spacer(minLength: 0)

                    metaBlock(scale: scale)
                        .padding(.bottom, 2 * scale)
                }
                .padding(.horizontal, 14 * scale)
                .padding(.vertical, 8 * scale)
                .shadow(color: .black.opacity(0.4), radius: 2.5, y: 1)
                .animation(.easeInOut(duration: 0.28), value: showFrozenDetails)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }

    private func titleText(scale: CGFloat) -> some View {
        let prefix = event.isStopped
            ? WL("label_frozen")
            : WL(isFuture ? "label_until" : "label_since")

        var base = AttributeContainer()
        base.font = .system(size: 14 * scale, weight: .semibold)
        base.kern = 0.6 * scale

        var titleAttr = AttributedString(event.title)
        titleAttr.mergeAttributes(base)
        titleAttr.foregroundColor = .white

        var prefixAttr = AttributedString(" " + prefix)
        prefixAttr.mergeAttributes(base)
        prefixAttr.foregroundColor = .white.opacity(0.7)

        return Text(titleAttr + prefixAttr)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 2)
    }

    private func daysBlock(scale: CGFloat) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 3 * scale) {
            Text("\(days)")
                .font(.system(size: daysFontSize(for: days) * scale, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(WL("day_unit"))
                .font(.system(size: 12 * scale, weight: .medium))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.72))
                .padding(.bottom, 4 * scale)
        }
        .frame(maxWidth: .infinity)
    }

    private func metaBlock(scale: CGFloat) -> some View {
        VStack(spacing: 3 * scale) {
            Text(showFrozenDetails ? frozenSinceText : targetDateText)
                .font(.system(size: 10 * scale, weight: .regular))
                .foregroundStyle(.white.opacity(showFrozenDetails ? 0.72 : 0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .contentTransition(.opacity)
                .id(showFrozenDetails ? "frozen-date" : "target-date")

            Group {
                if showFrozenDetails {
                    Text(WatchTimeUtils.clockTime(event.stoppedAtValue ?? targetDate))
                        .font(.system(size: 12 * scale, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.9))
                } else if event.isStopped {
                    let t = WatchTimeUtils.detailedTime(
                        targetDate: targetDate,
                        now: event.stoppedAtValue ?? targetDate
                    )
                    Text(String(format: "%02d:%02d:%02d", t.hours, t.minutes, t.seconds))
                        .font(.system(size: 12 * scale, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let t = WatchTimeUtils.detailedTime(targetDate: targetDate, now: context.date)
                        Text(String(format: "%02d:%02d:%02d", t.hours, t.minutes, t.seconds))
                            .font(.system(size: 12 * scale, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .contentTransition(.opacity)
            .id(showFrozenDetails ? "frozen-clock" : "relative-time")
        }
        .frame(maxWidth: .infinity)
    }

    private var targetDateText: String {
        "\(WL(isFuture ? "label_from" : "label_since_date")) \(WatchTimeUtils.shortDate(targetDate))"
    }

    private var frozenSinceText: String {
        "\(WL("label_frozen_since")) \(WatchTimeUtils.shortDate(event.stoppedAtValue ?? targetDate))"
    }

    private var readabilityScrim: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.22),
                .clear,
                .black.opacity(0.48)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func backgroundImage(size: CGSize) -> some View {
        let _ = backgroundRevision
        if let image = WatchBackgroundStore.loadImage(named: event.backgroundFileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            LinearGradient(
                colors: [Color(white: 0.2), Color(white: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: size.width, height: size.height)
        }
    }

    private func layoutScale(for size: CGSize) -> CGFloat {
        min(max(size.height / 198, 0.82), 1.08)
    }

    private func daysFontSize(for days: Int) -> CGFloat {
        switch String(days).count {
        case 6...: return 28
        case 5: return 34
        case 4: return 42
        case 3: return 50
        default: return 56
        }
    }
}

#Preview("累计") {
    WatchPosterView(
        event: WatchSyncEvent(
            id: 1,
            title: "糖方科技成立",
            targetDate: Date().addingTimeInterval(-86400 * 400).timeIntervalSince1970,
            isFuture: false,
            mode: "accumulate",
            backgroundFileName: nil,
            isPinned: true,
            maskOpacity: 0.35,
            position: 0,
            stoppedAt: nil
        )
    )
}

#Preview("定格") {
    WatchPosterView(
        event: WatchSyncEvent(
            id: 2,
            title: "毕业那天",
            targetDate: Date().addingTimeInterval(-86400 * 100).timeIntervalSince1970,
            isFuture: false,
            mode: "accumulate",
            backgroundFileName: nil,
            isPinned: false,
            maskOpacity: 0.35,
            position: 1,
            stoppedAt: Date().addingTimeInterval(-86400 * 10).timeIntervalSince1970
        )
    )
}
