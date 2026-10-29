import SwiftUI

struct MinesweeperView: View {
    @State private var model = MinesweeperModel()
    @State private var flagMode = false
    @State private var isGenerating = false
    @State private var result: GameResult?

    @AppStorage("mines-level") private var levelRaw = MinesweeperLevel.easy.rawValue
    @AppStorage("mines-best-easy") private var bestEasy = 0
    @AppStorage("mines-best-medium") private var bestMedium = 0
    @AppStorage("mines-best-hard") private var bestHard = 0

    var body: some View {
        VStack(spacing: 16) {
            scores
            GeometryReader { geo in
                board(available: min(geo.size.width, 560, geo.size.height))
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            actions
        }
        .padding(16)
        .sensoryFeedback(.impact, trigger: model.moves)
        .sensoryFeedback(trigger: model.outcome) { _, outcome in
            switch outcome {
            case .won: .success
            case .lost: .error
            case nil: nil
            }
        }
        .onGameActivityChange { model.setActive($0) }
        .onChange(of: levelRaw, initial: true) { _, raw in
            let level = MinesweeperLevel(rawValue: raw) ?? .easy
            if level != model.level { startNew(level: level) }
        }
        .onChange(of: model.outcome) { _, outcome in
            if let outcome { finish(outcome) }
        }
        .gameResultAlert($result, buttonTitle: "Nova igra") { model.newGame() }
    }

    // MARK: Gornji red

    private var scores: some View {
        HStack(spacing: 10) {
            ScoreCard(title: "Mine", value: "\(model.minesLeft)", tint: Theme.cyan)
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                ScoreCard(title: "Vrijeme", value: GameTimer.format(model.timer.elapsed(at: context.date)),
                          tint: Theme.cyan)
            }
            ScoreCard(title: "Rekord", value: best(for: model.level) == 0 ? "—"
                      : GameTimer.format(Double(best(for: model.level)) / 1000), tint: Theme.gold)
        }
    }

    // MARK: Ploča

    private func maxCellSize(_ level: MinesweeperLevel) -> CGFloat {
        switch level {
        case .easy: 48
        case .medium: 38
        case .hard: 30
        }
    }

    private func board(available: CGFloat) -> some View {
        let padding: CGFloat = 7, gap: CGFloat = 2
        let columns = CGFloat(model.cols)
        let cell = max(12, min(maxCellSize(model.level),
                               ((available - 2 * padding - (columns - 1) * gap) / columns).rounded(.down)))
        let side = columns * cell + (columns - 1) * gap + 2 * padding

        return Grid(horizontalSpacing: gap, verticalSpacing: gap) {
            ForEach(0..<model.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<model.cols, id: \.self) { column in
                        let index = row * model.cols + column
                        MineCell(cell: model.cells[index], isExploded: model.outcome == .lost(exploded: index),
                                 isWrongFlag: model.isWrongFlag(index), size: cell,
                                 row: row + 1, column: column + 1,
                                 tap: { tap(index) }, longPress: { model.toggleFlag(index) })
                    }
                }
            }
        }
        .padding(padding)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityHint(model.mayNeedGuess
                           ? "Ova ploča možda traži pogađanje."
                           : "Ploča se može riješiti logikom, bez pogađanja.")
    }

    // MARK: Gumbi

    private var actions: some View {
        HStack(spacing: 12) {
            Picker("Način", selection: $flagMode) {
                Text("Otkrij").tag(false)
                Text("Zastavica").tag(true)
            }
            .pickerStyle(.segmented)
            .controlSize(.large)

            Button { startNew() } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
            .accessibilityLabel("Nova igra")
        }
    }

    // MARK: Tijek igre

    private func tap(_ index: Int) {
        if flagMode {
            model.toggleFlag(index)
        } else if model.isFirstMove {
            revealFirst(index)
        } else {
            model.reveal(index)
        }
    }

    /// Prvi dodir: raspored mina se traži u pozadini (do 2 s), da sučelje ne zastane.
    private func revealFirst(_ index: Int) {
        guard !isGenerating, !model.cells[index].isFlagged else { return }
        isGenerating = true
        let level = model.level
        Task {
            let layout = await Task.detached(priority: .userInitiated) {
                MinesweeperLogic.makeLayout(level: level, safe: index)
            }.value
            if level == model.level, model.isFirstMove { model.reveal(index, layout: layout) }
            isGenerating = false
        }
    }

    private func startNew(level: MinesweeperLevel? = nil) {
        result = nil
        model.newGame(level: level)
    }

    private func finish(_ outcome: MinesweeperModel.Outcome) {
        let time = GameTimer.format(model.finishTime ?? 0)
        switch outcome {
        case .lost:
            result = GameResult(title: "Kraj igre", message: "Bum! Nagazio si minu.\nVrijeme \(time)\nPokušaj ponovno!")
        case .won:
            let level = model.level
            let ms = Int((model.finishTime ?? 0) * 1000)
            let previous = best(for: level)
            let isRecord = previous == 0 || ms < previous
            if isRecord { setBest(ms, for: level) }
            let message = isRecord
                ? "★ Novi rekord! ★\nNajbolji rezultat za razinu \(level.label)!"
                : "Rekord (\(level.label)): \(GameTimer.format(Double(previous) / 1000))."
            result = GameResult(title: "Pobjeda!", message: "Vrijeme \(time)\n\(message)")
        }
    }

    private func best(for level: MinesweeperLevel) -> Int {
        switch level {
        case .easy: bestEasy
        case .medium: bestMedium
        case .hard: bestHard
        }
    }

    private func setBest(_ ms: Int, for level: MinesweeperLevel) {
        switch level {
        case .easy: bestEasy = ms
        case .medium: bestMedium = ms
        case .hard: bestHard = ms
        }
    }
}

// MARK: - Polje

private struct MineCell: View {
    let cell: MinesweeperModel.Cell
    let isExploded: Bool
    let isWrongFlag: Bool
    let size: CGFloat
    let row: Int
    let column: Int
    let tap: () -> Void
    let longPress: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(fill)
            content
        }
        .frame(width: size, height: size)
        .shadow(color: isExploded ? Theme.accent.opacity(0.6) : .clear, radius: 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: tap)
        .onLongPressGesture(minimumDuration: 0.6, perform: longPress)
        .accessibilityElement()
        .accessibilityLabel("Redak \(row), stupac \(column)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(cell.isRevealed ? [] : .isButton)
        .accessibilityAction(named: cell.isFlagged ? "Skini zastavicu" : "Postavi zastavicu", longPress)
    }

    @ViewBuilder
    private var content: some View {
        if cell.isFlagged && !cell.isRevealed {
            MarkGlyph(isX: true, side: size * 0.72, weight: 3.4)
        } else if cell.isRevealed {
            if cell.isMine {
                MarkGlyph(isX: false, side: size * 0.72, weight: 3.4,
                          color: isExploded ? Theme.onAccent : Theme.cyan)
            } else if cell.adjacent > 0 {
                Text("\(cell.adjacent)")
                    .font(.system(size: size * 0.55, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.mineNumber(cell.adjacent))
            }
        }
    }

    private var fill: Color {
        if isExploded { return Theme.accent }
        if isWrongFlag { return Theme.accent.opacity(0.14) }
        return cell.isRevealed ? Theme.cell : Theme.line
    }

    private var accessibilityValue: String {
        if cell.isFlagged && !cell.isRevealed { return "zastavica" }
        guard cell.isRevealed else { return "zatvoreno" }
        if cell.isMine { return "mina" }
        return cell.adjacent == 0 ? "prazno" : "\(cell.adjacent)"
    }
}

#Preview {
    MinesweeperView()
        .background(XOBrand.background)
}
