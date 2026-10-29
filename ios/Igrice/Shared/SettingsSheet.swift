import SwiftUI

/// Postavke: razina (samo Minolovac i Neboderi) i tema.
struct SettingsSheet: View {
    let game: Game

    @Environment(\.dismiss) private var dismiss
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .auto
    @AppStorage("mines-level") private var minesLevel = "easy"
    @AppStorage("sky-mode") private var skyMode = "classic"

    private var level: Binding<String> {
        switch game {
        case .minesweeper: $minesLevel
        case .skyscrapers: $skyMode
        default: .constant("")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SheetHeader(title: "Postavke") { dismiss() }

            if !game.levels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SettingLabel(text: "Razina")
                    SegmentedControl(options: game.levels.map { (value: $0.id, label: $0.label) }, selection: level)
                    Text(game.levels.first { $0.id == level.wrappedValue }?.hint ?? "")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.muted)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SettingLabel(text: "Tema")
                SegmentedControl(options: ThemePreference.allCases.map { (value: $0, label: $0.label) }, selection: $theme)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.surface)
    }
}

private struct SettingLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.muted)
    }
}

/// Naslov prozorčića s gumbom za zatvaranje.
struct SheetHeader: View {
    let title: String
    let close: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.surfaceRaised))
            }
            .accessibilityLabel("Zatvori")
        }
    }
}
