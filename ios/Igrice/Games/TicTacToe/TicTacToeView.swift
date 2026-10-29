import SwiftUI

struct TicTacToeView: View {
    @State private var model = TicTacToeModel()
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 16) {
            scores
            GeometryReader { geo in
                board(side: min(geo.size.width, geo.size.height, 420))
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            actions
        }
        .padding(16)
        .sensoryFeedback(.impact, trigger: model.cells.compactMap { $0 }.count)
        .task(id: model.outcome) {
            guard model.outcome != nil else { showResult = false; return }
            try? await Task.sleep(for: .milliseconds(700))
            if !Task.isCancelled { showResult = true }
        }
        .alert(resultTitle, isPresented: $showResult) {
            Button("Igraj opet") { model.newGame() }
        } message: {
            Text(resultMessage)
        }
    }

    private var scores: some View {
        HStack(spacing: 10) {
            ScoreCard(title: Player.x.name, value: "\(model.scoreX)", tint: Theme.accent,
                      isActive: !model.isOver && model.current == .x)
            ScoreCard(title: "Remi", value: "\(model.scoreDraws)", tint: Theme.gold)
            ScoreCard(title: Player.o.name, value: "\(model.scoreO)", tint: Theme.cyan,
                      isActive: !model.isOver && model.current == .o)
        }
    }

    private func board(side: CGFloat) -> some View {
        let cellSide = (side - 2 * 15 - 2 * 10) / 3
        return Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        CellView(player: model.cells[index], isWinner: winningLine.contains(index),
                                 position: index + 1, side: cellSide) {
                            model.play(index)
                        }
                    }
                }
            }
        }
        .padding(15)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Resetiraj bodove") { model.resetScores() }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

            Button { model.newGame() } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
            .accessibilityLabel("Nova igra")
        }
    }

    private var winningLine: [Int] {
        if case .win(_, let line) = model.outcome { return line }
        return []
    }

    private var resultTitle: String {
        switch model.outcome {
        case .win(let player, _): "Pobijedio \(player.name)!"
        default: "Remi!"
        }
    }

    private var resultMessage: String {
        switch model.outcome {
        case .win: "Čestitke!"
        default: "Nitko nije pobijedio ovaj put."
        }
    }
}

// MARK: - Polje

private struct CellView: View {
    let player: Player?
    let isWinner: Bool
    let position: Int
    let side: CGFloat
    let tap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: tap) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(fill)
                RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 2)
                if let player {
                    glyph(for: player)
                        .frame(width: glyphSide, height: glyphSide)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .frame(width: side, height: side)
            .shadow(color: isWinner ? tint.opacity(0.5) : .clear, radius: 9)
            .scaleEffect(pulse ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25, bounce: 0.3), value: player)
        .onChange(of: isWinner) { _, winner in
            if winner {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
            } else {
                withAnimation(.default) { pulse = false }
            }
        }
        .accessibilityLabel("Polje \(position)")
        .accessibilityValue(player.map { $0 == .x ? "X" : "O" } ?? "prazno")
    }

    private var tint: Color { player == .o ? Theme.cyan : Theme.accent }

    private var fill: Color {
        guard player != nil else { return Theme.cell }
        return tint.opacity(isWinner ? 0.22 : 0.09)
    }

    private var border: Color {
        guard player != nil else { return .clear }
        return isWinner ? tint : tint.opacity(0.4)
    }

    /// Znak zauzima 58 % polja, a potez je 2,9 od 24 jedinice oblika (kao .glyph u index.html).
    private var glyphSide: CGFloat { side * 0.58 }

    @ViewBuilder
    private func glyph(for player: Player) -> some View {
        let style = StrokeStyle(lineWidth: glyphSide * 2.9 / 24, lineCap: .round)
        switch player {
        case .x: XGlyph().stroke(Theme.accent, style: style)
        case .o: OGlyph().stroke(Theme.cyan, style: style)
        }
    }
}

/// X kao u XO_SVG: mreža 24 × 24, krakovi od 6,5 do 17,5.
private struct XGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path()
        path.move(to: point(6.5, 6.5)); path.addLine(to: point(17.5, 17.5))
        path.move(to: point(17.5, 6.5)); path.addLine(to: point(6.5, 17.5))
        return path
    }
}

/// O kao u XO_SVG: krug polumjera 6,4 u mreži 24 × 24.
private struct OGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        return Path(ellipseIn: CGRect(x: rect.minX + 5.6 * s, y: rect.minY + 5.6 * s, width: 12.8 * s, height: 12.8 * s))
    }
}

#Preview {
    TicTacToeView()
        .background(XOBrand.background)
}
