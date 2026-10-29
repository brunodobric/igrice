import SwiftUI

/// Pravila i savjet za odabranu igru.
struct InfoSheet: View {
    let game: Game

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(game.rules.indices, id: \.self) { index in
                        Label(game.rules[index], systemImage: "\(index + 1).circle.fill")
                    }
                } footer: {
                    Text(game.hint)
                }
            }
            .navigationTitle(game.title)
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
