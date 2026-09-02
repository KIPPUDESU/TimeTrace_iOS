import SwiftUI
import SwiftData

// 导航胶囊 切符最喜欢的原生液态玻璃控件www

struct ContentView: View {
    // 日夜模式，设置页里切换后这里自动跟着变
    @AppStorage(AppPreferenceKeys.themeMode) private var themeModeRaw = ThemeMode.system.rawValue

    @Query(sort: [
        SortDescriptor(\DateEvent.position),
        SortDescriptor(\DateEvent.id, order: .reverse)
    ]) private var events: [DateEvent]

    // 置顶的排在前面
    private var orderedEvents: [DateEvent] {
        events.filter(\.isPinned) + events.filter { !$0.isPinned }
    }

    // 当前选中哪个标签
    @State private var selection = Screen.timeline
    // 往右还是往左
    @State private var goingRight = true
    @State private var detailReselectTick = 0

    // 换标签时先算方向
    private var selectionBinding: Binding<Screen> {
        Binding(
            get: { selection },
            set: { target in
                // 点的是详情，通知回本组第一张
                if target == selection {
                    if target == .detail { detailReselectTick += 1 }
                    return
                }
                goingRight = target.order > selection.order
                selection = target
            }
        )
    }

    // 三档日夜模式对应的外观，跟随系统就不强制
    private var colorScheme: ColorScheme? {
        (ThemeMode(rawValue: themeModeRaw) ?? .system).colorScheme
    }

    var body: some View {
        // 标签只有图标
        TabView(selection: selectionBinding) {
            Tab(value: Screen.timeline) {
                // 分层
                HomeScreen()
                    .tabAppear(isActive: selection == .timeline, goingRight: goingRight, movesWholePage: false)
            } label: {
                Image(systemName: "calendar")
                    // 这是无障碍功能
                    // 补一个屏幕上看不见的名字
                    .accessibilityLabel(L("timeline_title"))
            }

            Tab(value: Screen.detail) {
                // 没有记录时传 0
                DetailScreen(
                    events: orderedEvents,
                    initialEventId: orderedEvents.first?.id ?? 0,
                    // 回就切回时间轴
                    onBack: { selection = .timeline },
                    // 点击详情回到本组第一张
                    reselectTick: detailReselectTick
                )
                .tabAppear(isActive: selection == .detail, goingRight: goingRight, movesWholePage: false)
            } label: {
                Image(systemName: "rectangle.stack")
                    // 补
                    .accessibilityLabel(L("detail_title"))
            }

            Tab(value: Screen.settings) {
                // 设置页自己分层
                SettingsScreen()
                    .tabAppear(isActive: selection == .settings, goingRight: goingRight, movesWholePage: false)
            } label: {
                Image(systemName: "gearshape")
                    // 补
                    .accessibilityLabel(L("settings_title"))
            }
        }
        // 选中的标签用 secondary
        .tint(TimeTracePalette.secondary)
        // 背景色
        .background(TimeTracePalette.background.ignoresSafeArea())
        // 锁整个 App 的日夜模式
        .preferredColorScheme(colorScheme)
    }
}

// 三个标签
enum Screen {
    case timeline
    case detail
    case settings

    // 位置标号
    var order: Int {
        switch self {
        case .timeline: return 0
        case .detail: return 1
        case .settings: return 2
        }
    }
}

// 让内容演出
private struct TabAppear: ViewModifier {
    let isActive: Bool
    let goingRight: Bool
    let movesWholePage: Bool

    private let duration = 0.60
    // 起步位
    private let distance: CGFloat = 400

    @State private var shown = false

    // 这一刻该横移多少
    private var slide: CGFloat {
        shown ? 0 : (goingRight ? distance : -distance)
    }

    func body(content: Content) -> some View {
        content
            .offset(x: movesWholePage ? slide : 0)
            // 拿距离
            .environment(\.tabSlideOffset, slide)
            // 页面自己决定淡入
            .environment(\.tabReveal, shown ? 1 : 0)
            .onChange(of: isActive, initial: true) { _, active in
                guard active else {
                    // 归零
                    shown = false
                    return
                }
                withAnimation(.smooth(duration: duration)) { shown = true }
            }
    }
}

private struct TabSlideOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var tabSlideOffset: CGFloat {
        get { self[TabSlideOffsetKey.self] }
        set { self[TabSlideOffsetKey.self] = newValue }
    }
}

private struct TabRevealKey: EnvironmentKey {
    static let defaultValue: Double = 1
}

extension EnvironmentValues {
    var tabReveal: Double {
        get { self[TabRevealKey.self] }
        set { self[TabRevealKey.self] = newValue }
    }
}

extension View {
    // 传选中 切换方向
    func tabAppear(isActive: Bool, goingRight: Bool, movesWholePage: Bool = true) -> some View {
        modifier(TabAppear(isActive: isActive, goingRight: goingRight, movesWholePage: movesWholePage))
    }
}

#Preview {
    ContentView()
        .modelContainer(MockData.previewContainer())
}

#Preview("深色模式") {
    ContentView()
        .modelContainer(MockData.previewContainer())
        .preferredColorScheme(.dark)
}
