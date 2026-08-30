import SwiftUI
import SwiftData

struct ContentView: View {
    // 日夜模式，设置页里切换后这里自动跟着变
    @AppStorage(AppPreferenceKeys.themeMode) private var themeModeRaw = ThemeMode.system.rawValue

    // 三档日夜模式对应的外观，跟随系统就不强制
    private var colorScheme: ColorScheme? {
        (ThemeMode(rawValue: themeModeRaw) ?? .system).colorScheme
    }

    var body: some View {
        HomeScreen()
            // 锁整个 App 的日夜模式
            .preferredColorScheme(colorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(MockData.previewContainer())
}
