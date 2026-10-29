import SwiftUI

private struct GamePausedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Postavlja ga ContentView dok je otvoren prozorčić (Postavke, Pravila): mjerači staju.
    var isGamePaused: Bool {
        get { self[GamePausedKey.self] }
        set { self[GamePausedKey.self] = newValue }
    }
}

private struct GameActivityModifier: ViewModifier {
    let perform: (Bool) -> Void

    @Environment(\.isGamePaused) private var paused
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    private var active: Bool { visible && !paused && scenePhase == .active }

    func body(content: Content) -> some View {
        content
            .onAppear { visible = true }
            .onDisappear { visible = false }
            .onChange(of: active) { _, value in perform(value) }
    }
}

extension View {
    /// Javlja je li igra trenutno aktivna: na ekranu, bez otvorenog prozorčića i u prvom planu.
    /// Mjerač vremena se prema tome zaustavlja i nastavlja (onEnter i onLeave u index.html).
    func onGameActivityChange(_ perform: @escaping (Bool) -> Void) -> some View {
        modifier(GameActivityModifier(perform: perform))
    }
}
