import SwiftUI

/// Plutajuća poluprozirna traka s četiri igre (dizajn paket XO Igrice).
struct FloatingTabBar: View {
    @Binding var selection: Game
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Game.allCases) { game in
                tab(for: game)
            }
        }
        .padding(6)
        .frame(height: 70)
        .background {
            Capsule().fill(.ultraThinMaterial)
            Capsule().fill(Theme.glass)
        }
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
        .frame(maxWidth: 440)
    }

    private func tab(for game: Game) -> some View {
        let active = game == selection
        return Button {
            withAnimation(.snappy(duration: 0.25)) { selection = game }
        } label: {
            VStack(spacing: 3) {
                GameIcon(game: game, color: active ? Theme.accent : Theme.muted)
                    .frame(width: 22, height: 22)
                Text(game.title)
                    .font(.system(size: 10.5, weight: active ? .bold : .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(active ? Theme.text : Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if active {
                    Capsule()
                        .fill(Theme.surfaceRaised)
                        .matchedGeometryEffect(id: "pill", in: pill)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(game.title)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

#Preview {
    FloatingTabBar(selection: .constant(.minesweeper))
        .padding(16)
        .background(XOBrand.background)
}
