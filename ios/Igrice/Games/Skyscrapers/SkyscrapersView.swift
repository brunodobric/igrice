import SwiftUI

struct SkyscrapersView: View {
    @State private var model = SkyscrapersModel()
    @State private var result: GameResult?
    @State private var generation = 0

    @AppStorage("sky-mode") private var modeRaw = SkyscrapersMode.classic.rawValue
    @AppStorage("sky-best-easy") private var bestEasy = 0
    @AppStorage("sky-best-classic") private var bestClassic = 0
    @AppStorage("sky-best-pro") private var bestPro = 0

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
        .sensoryFeedback(.impact, trigger: model.edits)
        .onGameActivityChange { model.setActive($0) }
        .onChange(of: modeRaw, initial: true) { _, raw in
            let mode = SkyscrapersMode(rawValue: raw) ?? .classic
            if model.clues == nil || mode != model.mode { startNew(mode: mode) }
        }
        .onChange(of: model.isSolved) { _, solved in
            if solved { finish() }
        }
        .gameResultAlert($result, buttonTitle: "Nova zagonetka") { startNew() }
    }

    // MARK: Gornji red

    private var scores: some View {
        HStack(spacing: 10) {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                ScoreCard(title: "Vrijeme", value: GameTimer.format(model.timer.elapsed(at: context.date)),
                          tint: Theme.cyan)
            }
            ScoreCard(title: "Rekord", value: best(for: model.mode) == 0 ? "—"
                      : GameTimer.format(Double(best(for: model.mode)) / 1000), tint: Theme.gold)
        }
    }

    // MARK: Ploča

    @ViewBuilder
    private func board(available: CGFloat) -> some View {
        let lines = SkyscrapersLogic.size + 2
        let padding: CGFloat = 11, gap: CGFloat = 5
        let count = CGFloat(lines)
        let cell = max(28, min(62, ((available - 2 * padding - (count - 1) * gap) / count).rounded(.down)))
        let side = count * cell + (count - 1) * gap + 2 * padding

        if let clues = model.clues {
            let errors = model.errors
            Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                ForEach(0..<lines, id: \.self) { rr in
                    GridRow {
                        ForEach(0..<lines, id: \.self) { cc in
                            boardItem(row: rr, column: cc, lines: lines, size: cell, clues: clues, errors: errors)
                        }
                    }
                }
            }
            .padding(padding)
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
            .accessibilityElement(children: .contain)
            .accessibilityHint("Popunjeno \(model.filledCount) od \(SkyscrapersLogic.size * SkyscrapersLogic.size).")
        } else {
            ProgressView()
                .frame(width: side, height: side)
        }
    }

    /// Jedno mjesto u mreži 7 × 7: kut, trag uz rub ili polje za visinu.
    @ViewBuilder
    private func boardItem(row rr: Int, column cc: Int, lines: Int, size: CGFloat,
                           clues: SkyscrapersClues, errors: SkyscrapersErrors) -> some View {
        let last = lines - 1
        if (rr == 0 || rr == last) && (cc == 0 || cc == last) {
            Color.clear.frame(width: size, height: size)
        } else if rr == 0 {
            clue(.top, cc - 1, clues, errors, size)
        } else if rr == last {
            clue(.bottom, cc - 1, clues, errors, size)
        } else if cc == 0 {
            clue(.left, rr - 1, clues, errors, size)
        } else if cc == last {
            clue(.right, rr - 1, clues, errors, size)
        } else {
            let index = SkyscrapersLogic.index(rr - 1, cc - 1)
            HeightCell(height: model.values[index], hasError: errors.cells.contains(index),
                       isSolved: model.isSolved, size: size, row: rr, column: cc,
                       raise: { model.raise(index) }, lower: { model.lower(index) })
        }
    }

    private func clue(_ side: SkyscrapersSide, _ index: Int, _ clues: SkyscrapersClues,
                      _ errors: SkyscrapersErrors, _ size: CGFloat) -> some View {
        ClueLabel(value: clues[side][index], isBad: errors.clues.contains(SkyscrapersClueID(side: side, index: index)),
                  size: size, side: side, index: index + 1)
    }

    // MARK: Gumbi

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Očisti") { model.clear() }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

            Button { startNew() } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
            .accessibilityLabel("Nova zagonetka")
        }
    }

    // MARK: Tijek igre

    /// Zagonetka se traži u pozadini (Klasično i Pro mogu trajati), pa sučelje ne zastaje.
    private func startNew(mode: SkyscrapersMode? = nil) {
        result = nil
        let mode = mode ?? model.mode
        generation += 1
        let token = generation
        Task {
            let clues = await Task.detached(priority: .userInitiated) {
                SkyscrapersLogic.makePuzzle(mode: mode)
            }.value
            guard token == generation else { return }   // u međuvremenu je zatražena druga
            model.start(clues, mode: mode)
        }
    }

    private func finish() {
        let mode = model.mode
        let ms = Int((model.solveTime ?? 0) * 1000)
        let previous = best(for: mode)
        let isRecord = previous == 0 || ms < previous
        if isRecord { setBest(ms, for: mode) }
        let message = isRecord
            ? "★ Novi rekord! ★"
            : "Tvoj rekord je \(GameTimer.format(Double(previous) / 1000))."
        result = GameResult(title: "Riješeno!",
                            message: "Vrijeme \(GameTimer.format(model.solveTime ?? 0))\n\(message)")
    }

    private func best(for mode: SkyscrapersMode) -> Int {
        switch mode {
        case .easy: bestEasy
        case .classic: bestClassic
        case .pro: bestPro
        }
    }

    private func setBest(_ ms: Int, for mode: SkyscrapersMode) {
        switch mode {
        case .easy: bestEasy = ms
        case .classic: bestClassic = ms
        case .pro: bestPro = ms
        }
    }
}

// MARK: - Polje i trag

private struct HeightCell: View {
    let height: Int
    let hasError: Bool
    let isSolved: Bool
    let size: CGFloat
    let row: Int
    let column: Int
    let raise: () -> Void
    let lower: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 10).fill(Theme.cell)
            // stupac boje raste s visinom: 1/5 do 5/5 polja
            Rectangle()
                .fill(Theme.cyan.opacity(0.25))
                .frame(height: size * CGFloat(height) / CGFloat(SkyscrapersLogic.size))
                .animation(.easeOut(duration: 0.2), value: height)
            if height > 0 {
                Text("\(height)")
                    .font(.system(size: size * 0.45, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.text)
                    .frame(width: size, height: size)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(border, lineWidth: 1.5))
        .frame(width: size, height: size)
        .shadow(color: glow, radius: 8)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture(perform: raise)
        .onLongPressGesture(minimumDuration: 0.6, perform: lower)
        .accessibilityElement()
        .accessibilityLabel("Redak \(row), stupac \(column)")
        .accessibilityValue(height == 0 ? "prazno" : "visina \(height)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: raise()
            case .decrement: lower()
            @unknown default: break
            }
        }
    }

    private var border: Color {
        if hasError { return Theme.accent }
        return isSolved ? Theme.cyan.opacity(0.6) : Theme.line
    }

    private var glow: Color {
        if hasError { return Theme.accent.opacity(0.45) }
        return isSolved ? Theme.cyan.opacity(0.35) : .clear
    }
}

/// Broj nebodera koji se vidi iz tog smjera; prazno ako trag nije zadan.
private struct ClueLabel: View {
    let value: Int
    let isBad: Bool
    let size: CGFloat
    let side: SkyscrapersSide
    let index: Int

    var body: some View {
        Text(value == 0 ? "" : "\(value)")
            .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
            .foregroundStyle(isBad ? Theme.accent : Theme.gold)
            .shadow(color: isBad ? Theme.accent.opacity(0.6) : .clear, radius: 5)
            .frame(width: size, height: size)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityHidden(value == 0)
    }

    private var label: String {
        let direction: String
        switch side {
        case .top: direction = "Gore, stupac \(index)"
        case .bottom: direction = "Dolje, stupac \(index)"
        case .left: direction = "Lijevo, redak \(index)"
        case .right: direction = "Desno, redak \(index)"
        }
        return "\(direction): vidi se \(value)"
    }
}

#Preview {
    SkyscrapersView()
        .background(XOBrand.background)
}
