import SwiftUI

/// Pravila i savjet za odabranu igru.
struct InfoSheet: View {
    let game: Game

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SheetHeader(title: game.title) { dismiss() }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(game.rules.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.onAccent)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Theme.accent))
                        Text(game.rules[index])
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.text)
                    }
                }
            }

            Text(game.hint)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.muted)

            Spacer(minLength: 0)

            Button("U redu") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.surface)
    }
}
