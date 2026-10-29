import SwiftUI

private enum ActiveSheet: String, Identifiable {
    case settings, info
    var id: String { rawValue }
}

/// Glavni ekran: sistemska tab traka s četiri igre. Svaka igra ima svoju
/// navigacijsku traku s Postavkama i Pravilima.
struct ContentView: View {
    @State private var game: Game = .ticTacToe
    @State private var sheet: ActiveSheet?

    var body: some View {
        TabView(selection: $game) {
            ForEach(Game.allCases) { game in
                GameScreen(game: game) { sheet = $0 }
                    .tabItem { Label(game.title, systemImage: game.symbol) }
                    .tag(game)
            }
        }
        .tint(Theme.accent)
        .environment(\.isGamePaused, sheet != nil)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .settings: SettingsSheet(game: game)
            case .info: InfoSheet(game: game)
            }
        }
    }
}

private struct GameScreen: View {
    let game: Game
    let present: (ActiveSheet) -> Void

    @ViewBuilder
    private var content: some View {
        switch game {
        case .ticTacToe: TicTacToeView()
        case .tango: TangoView()
        case .minesweeper: MinesweeperView()
        case .skyscrapers: SkyscrapersView()
        }
    }

    var body: some View {
        NavigationStack {
            content
                .background(XOBrand.background.ignoresSafeArea())
                .navigationTitle(game.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { present(.settings) } label: {
                            Label("Postavke", systemImage: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { present(.info) } label: {
                            Label("Pravila", systemImage: "info.circle")
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
