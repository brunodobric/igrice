import SwiftUI

/// Glavni ekran: gornji red, igra i plutajuća donja traka.
struct ContentView: View {
    @State private var game: Game = .ticTacToe
    @State private var sheet: ActiveSheet?

    private enum ActiveSheet: String, Identifiable {
        case settings, info
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            GamePlaceholderView(game: game)
        }
        .background(XOBrand.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selection: $game)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .settings: SettingsSheet(game: game)
            case .info: InfoSheet(game: game)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            TopBarButton(systemName: "gearshape", label: "Postavke") { sheet = .settings }

            Text(game.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Capsule().fill(Theme.surface))
                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))

            TopBarButton(systemName: "info", label: "Pravila") { sheet = .info }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

private struct TopBarButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.cyan)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.surface))
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }
}

/// Privremeni ekran dok igre ne budu portirane (faze 2 do 6).
private struct GamePlaceholderView: View {
    let game: Game

    var body: some View {
        VStack(spacing: 16) {
            GameIcon(game: game, color: Theme.cyan, lineWidth: 3)
                .frame(width: 72, height: 72)
            Text(game.title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.text)
            Text("Igra uskoro stiže.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
