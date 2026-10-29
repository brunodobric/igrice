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
        NavigationStack {
            Form {
                if !game.levels.isEmpty {
                    Section {
                        Picker("Razina", selection: level) {
                            ForEach(game.levels) { Text($0.label).tag($0.id) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    } header: {
                        Text("Razina")
                    } footer: {
                        Text(game.levels.first { $0.id == level.wrappedValue }?.hint ?? "")
                    }
                }

                Section("Tema") {
                    Picker("Tema", selection: $theme) {
                        ForEach(ThemePreference.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            .navigationTitle("Postavke")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotovo") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
