import SwiftUI
import SwiftData

// 导航胶囊

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
        TabView(selection: $selection) {
            Tab(L("timeline_title"), systemImage: "calendar", value: Screen.timeline) {
                HomeScreen()
            }

            Tab(L("detail_title"), systemImage: "rectangle.stack", value: Screen.detail) {
                // 没有记录时传 0
                DetailScreen(
                    events: events,
                    initialEventId: events.first?.id ?? 0,
                    // 回就切回时间轴
                    onBack: { selection = .timeline }
                )
            }

            Tab(L("settings_title"), systemImage: "gearshape", value: Screen.settings) {
                SettingsScreen()
            }
        }
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
