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

    // 三档日夜模式对应的外观，跟随系统就不强制
    private var colorScheme: ColorScheme? {
        (ThemeMode(rawValue: themeModeRaw) ?? .system).colorScheme
    }

    var body: some View {
        // 标签只有图标
        TabView(selection: $selection) {
            Tab(value: Screen.timeline) {
                HomeScreen()
                    .tabAppear(isActive: selection == .timeline)
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
                    onBack: { selection = .timeline }
                )
                .tabAppear(isActive: selection == .detail)
            } label: {
                Image(systemName: "rectangle.stack")
                    // 补
                    .accessibilityLabel(L("detail_title"))
            }

            Tab(value: Screen.settings) {
                SettingsScreen()
                    .tabAppear(isActive: selection == .settings)
            } label: {
                Image(systemName: "gearshape")
                    // 补
                    .accessibilityLabel(L("settings_title"))
            }
        }
        // 选中的标签用 secondary，跟安卓一致：选中偏灰，未选中是深色
        .tint(TimeTracePalette.secondary)
        // 锁整个 App 的日夜模式
        .preferredColorScheme(colorScheme)
    }
}

// 三个标签
enum Screen {
    case timeline
    case detail
    case settings
}

// 让内容演出
private struct TabAppear: ViewModifier {
    let isActive: Bool

    // 越大越慢
    private let duration = 1.00

    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            // 带 initial 是为了第一次切到这个标签时也能演，而不是直接蹦出来
            .onChange(of: isActive, initial: true) { _, active in
                guard active else {
                    shown = false
                    return
                }
                withAnimation(.smooth(duration: duration)) { shown = true }
            }
    }
}

extension View {
    // 传当前这个标签是不是选中的
    func tabAppear(isActive: Bool) -> some View {
        modifier(TabAppear(isActive: isActive))
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
