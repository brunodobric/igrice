import SwiftUI

@main
struct IgriceApp: App {
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .auto
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showSplash {
                    SplashView { showSplash = false }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(theme.colorScheme)
        }
    }
}
