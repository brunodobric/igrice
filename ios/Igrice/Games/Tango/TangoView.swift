import SwiftUI

struct TangoView: View {
    @State private var model = TangoModel()
    @AppStorage("tango-best-ms") private var bestMs = 0
    @State private var showErrors = false
    @State private var result: GameResult?
    @State private var isActive = false

    private static let saveKey = "tango-progress"

    var body: some View {
        VStack(spacing: 16) {
            scores
            GeometryReader { geo in
                board(available: min(geo.size.width, geo.size.height))
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            actions
        }
        .padding(16)
        .sensoryFeedback(.impact, trigger: model.edits)
        .onGameActivityChange { active in
            isActive = active
            model.setActive(active)
            if !active { save() }
        }
        .onChange(of: model.edits) { save() }
        .task {
            guard !model.isReady else { return }
            if let saved = GameStore.load(TangoSnapshot.self, key: Self.saveKey), model.restore(saved) {
                model.setActive(isActive)
            } else {
                model.newPuzzle()
            }
        }
        .task(id: model.edits) { await revealErrorsAfterDelay() }
        .onChange(of: model.isSolved) { _, solved in
            if solved { finish() }
        }
        .gameResultAlert($result, buttonTitle: "Nova zagonetka") { model.newPuzzle() }
    }

    // MARK: Gornji red

    private var scores: some View {
        HStack(spacing: 10) {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                ScoreCard(title: "Vrijeme", value: GameTimer.format(model.timer.elapsed(at: context.date)),
                          tint: Theme.cyan)
            }
            ScoreCard(title: "Rekord", value: bestMs == 0 ? "—" : GameTimer.format(Double(bestMs) / 1000),
                      tint: Theme.gold)
        }
    }

    // MARK: Ploča

    @ViewBuilder
    private func board(available: CGFloat) -> some View {
        if model.isReady {
            readyBoard(available: available)
        } else {
            ProgressView()
        }
    }

    private func readyBoard(available: CGFloat) -> some View {
        let padding: CGFloat = 11, gap: CGFloat = 6
        let count = CGFloat(TangoLogic.size)
        let cell = min(68, (min(available, 520) - 2 * padding - (count - 1) * gap) / count)
        let side = count * cell + (count - 1) * gap + 2 * padding
        let errors = showErrors ? model.errors : TangoErrors()

        func center(_ index: Int) -> CGPoint {
            let row = CGFloat(index / TangoLogic.size), column = CGFloat(index % TangoLogic.size)
            return CGPoint(x: padding + column * (cell + gap) + cell / 2,
                           y: padding + row * (cell + gap) + cell / 2)
        }

        return ZStack(alignment: .topLeading) {
            Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                ForEach(0..<TangoLogic.size, id: \.self) { row in
                    GridRow {
                        ForEach(0..<TangoLogic.size, id: \.self) { column in
                            let index = row * TangoLogic.size + column
                            TangoCell(mark: model.values[index], isGiven: model.puzzle.given[index] != nil,
                                      hasError: errors.cells.contains(index), isSolved: model.isSolved,
                                      position: index + 1, side: cell,
                                      tap: { model.tap(index) }, longPress: { model.toggleMoon(index) })
                        }
                    }
                }
            }
            .padding(padding)

            ForEach(Array(model.puzzle.links.enumerated()), id: \.offset) { offset, link in
                let a = center(link.pair.a), b = center(link.pair.b)
                LinkBadge(relation: link.relation, isBad: errors.links.contains(offset))
                    .position(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            }
        }
        .frame(width: side, height: side)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityHint("Dodir mijenja polje: prazno, X, O. Popunjeno \(model.filledCount) od \(TangoLogic.cellCount).")
    }

    // MARK: Gumbi

    private var actions: some View {
        HStack(spacing: 12) {
            Button { model.clear() } label: {
                Text("Očisti")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

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

    /// Crveno se prikaže tek 2 s nakon zadnje promjene, da brza ispravka (X u O) ne bljesne greškom.
    private func revealErrorsAfterDelay() async {
        showErrors = false
        guard !model.errors.cells.isEmpty else { return }
        try? await Task.sleep(for: .seconds(2))
        if !Task.isCancelled { showErrors = true }
    }

    private func finish() {
        let ms = Int((model.solveTime ?? 0) * 1000)
        let time = GameTimer.format(model.solveTime ?? 0)
        let isRecord = bestMs == 0 || ms < bestMs
        if isRecord { bestMs = ms }
        let message = isRecord
            ? "★ Novi rekord! ★"
            : "Tvoj rekord je \(GameTimer.format(Double(bestMs) / 1000))."
        result = GameResult(title: "Riješeno!", message: "Vrijeme \(time)\n\(message)")
    }

    private func save() {
        guard model.isReady else { return }
        GameStore.save(model.snapshot, key: Self.saveKey)
    }

    private func startNew() {
        result = nil
        model.newPuzzle()
    }
}

// MARK: - Polje

private struct TangoCell: View {
    let mark: TangoMark?
    let isGiven: Bool
    let hasError: Bool
    let isSolved: Bool
    let position: Int
    let side: CGFloat
    let tap: () -> Void
    let longPress: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(fill)
            RoundedRectangle(cornerRadius: 10).stroke(border, lineWidth: 2)
            if let mark {
                MarkGlyph(isX: mark == .x, side: side * 0.58)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .frame(width: side, height: side)
        .shadow(color: glow, radius: 8)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture(perform: tap)
        .onLongPressGesture(minimumDuration: 0.6, perform: longPress)
        .animation(.spring(duration: 0.25, bounce: 0.3), value: mark)
        .accessibilityElement()
        .accessibilityLabel("Polje \(position)")
        .accessibilityValue(mark.map { $0 == .x ? "X" : "O" } ?? "prazno")
        .accessibilityHint(isGiven ? "Zadano polje" : "")
        .accessibilityAddTraits(isGiven ? [] : .isButton)
        .accessibilityAction(named: "Postavi O", longPress)
    }

    private var fill: Color {
        if hasError { return Theme.accent.opacity(0.12) }
        return isGiven ? Theme.surfaceRaised : Theme.cell
    }

    private var border: Color {
        if hasError { return Theme.accent }
        return isSolved ? Theme.cyan.opacity(0.6) : .clear
    }

    private var glow: Color {
        if hasError { return Theme.accent.opacity(0.45) }
        return isSolved ? Theme.cyan.opacity(0.35) : .clear
    }
}

/// Znak = ili × između dva susjedna polja.
private struct LinkBadge: View {
    let relation: TangoRelation
    let isBad: Bool

    var body: some View {
        Text(relation == .same ? "=" : "×")
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(isBad ? Theme.accent : Theme.text)
            .frame(width: 22, height: 22)
            .background(Circle().fill(XOBrand.bgTop))
            .overlay(Circle().stroke(isBad ? Theme.accent : Theme.muted, lineWidth: 1.5))
            .shadow(color: isBad ? Theme.accent.opacity(0.5) : .clear, radius: 5)
            .allowsHitTesting(false)
            .accessibilityLabel(relation == .same ? "Ista polja" : "Različita polja")
    }
}

#Preview {
    TangoView()
        .background(XOBrand.background)
}
