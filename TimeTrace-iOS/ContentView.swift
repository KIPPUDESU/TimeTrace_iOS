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
            } label: {
                Image(systemName: "calendar")
                    // 这是无障碍功能
                    // 补一个屏幕上看不见的名字
                    .accessibilityLabel(L("timeline_title"))
            }

            Tab(value: Screen.detail) {
                // 没有记录时传 0
                DetailScreen(
                    events: events,
                    initialEventId: events.first?.id ?? 0,
                    // 回就切回时间轴
                    onBack: { selection = .timeline }
                )
            } label: {
                Image(systemName: "rectangle.stack")
                    // 补
                    .accessibilityLabel(L("detail_title"))
            }

            Tab(value: Screen.settings) {
                SettingsScreen()
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

#Preview {
    ContentView()
        .modelContainer(MockData.previewContainer())
}

#Preview("深色模式") {
    ContentView()
        .modelContainer(MockData.previewContainer())
        .preferredColorScheme(.dark)
}
