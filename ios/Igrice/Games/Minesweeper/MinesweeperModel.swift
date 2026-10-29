import Foundation
import Observation

enum MinesweeperLevel: String, CaseIterable, Codable {
    case easy, medium, hard

    var rows: Int { cols }
    var cols: Int {
        switch self {
        case .easy: 8
        case .medium: 12
        case .hard: 16
        }
    }

    var mines: Int {
        switch self {
        case .easy: 10
        case .medium: 30
        case .hard: 50
        }
    }

    var label: String {
        switch self {
        case .easy: "Lako"
        case .medium: "Srednje"
        case .hard: "Teško"
        }
    }
}

/// Raspored mina i brojeva uz mine, nastao nakon prvog dodira.
struct MinesLayout: Equatable, Sendable {
    var mines: Set<Int>
    var adjacency: [Int]          // broj susjednih mina; kod mina se ne čita
    var mayNeedGuess: Bool        // true samo ako ploča bez pogađanja nije nađena u zadanom roku
}

/// Susjedi svakog polja, izračunati jednom.
struct MinesGeometry: Sendable {
    let rows: Int
    let cols: Int
    let neighbours: [[Int]]

    init(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
        neighbours = (0..<rows * cols).map { i in
            let r = i / cols, c = i % cols
            var result: [Int] = []
            for dr in -1...1 {
                for dc in -1...1 where dr != 0 || dc != 0 {
                    let nr = r + dr, nc = c + dc
                    if nr >= 0, nr < rows, nc >= 0, nc < cols { result.append(nr * cols + nc) }
                }
            }
            return result
        }
    }
}

/// Generator ploče bez pogađanja i provjera rješivosti. Algoritam je prenesen iz index.html.
enum MinesweeperLogic {
    private enum Knowledge { case unknown, safe, mine }

    static func adjacency(mines: Set<Int>, geometry: MinesGeometry) -> [Int] {
        (0..<geometry.rows * geometry.cols).map { i in
            mines.contains(i) ? -1 : geometry.neighbours[i].filter { mines.contains($0) }.count
        }
    }

    /// Može li se raspored riješiti od `start` samo logikom? Simulira rješavača: otvaranje praznina,
    /// pa redom pravilo jednog polja, pravilo podskupa (1-2) i pravilo ukupnog broja mina.
    static func isNoGuess(mines: Set<Int>, adjacency: [Int], start: Int, geometry: MinesGeometry) -> Bool {
        let total = geometry.rows * geometry.cols
        var state = Array(repeating: Knowledge.unknown, count: total)

        func revealFlood(_ first: Int) {
            var stack = [first]
            while let c = stack.popLast() {
                if state[c] != .unknown || mines.contains(c) { continue }
                state[c] = .safe
                if adjacency[c] == 0 {
                    for n in geometry.neighbours[c] where state[n] == .unknown { stack.append(n) }
                }
            }
        }

        func openCell(_ u: Int) {
            if adjacency[u] == 0 { revealFlood(u) } else { state[u] = .safe }
        }

        revealFlood(start)

        var changed = true
        while changed {
            changed = false

            // jedno polje: broj s pronađenim svim minama, ostalo je sigurno; sve nepoznato su mine
            for i in 0..<total {
                guard state[i] == .safe, adjacency[i] != 0 else { continue }
                let nb = geometry.neighbours[i]
                let unknown = nb.filter { state[$0] == .unknown }
                if unknown.isEmpty { continue }
                let remaining = adjacency[i] - nb.filter { state[$0] == .mine }.count
                if remaining == 0 {
                    for u in unknown where state[u] == .unknown {
                        changed = true
                        openCell(u)
                    }
                } else if remaining == unknown.count {
                    for u in unknown {
                        state[u] = .mine
                        changed = true
                    }
                }
            }
            if changed { continue }

            // podskup (1-2): ako su nepoznata polja A podskup polja B, razlika ima B.mine - A.mine mina
            var constraints: [(cells: Set<Int>, mines: Int)] = []
            for i in 0..<total {
                guard state[i] == .safe, adjacency[i] != 0 else { continue }
                let nb = geometry.neighbours[i]
                let unknown = nb.filter { state[$0] == .unknown }
                if unknown.isEmpty { continue }
                constraints.append((Set(unknown), adjacency[i] - nb.filter { state[$0] == .mine }.count))
            }
            for (ai, a) in constraints.enumerated() {
                for (bi, b) in constraints.enumerated() {
                    if ai == bi || a.cells.count >= b.cells.count || !a.cells.isSubset(of: b.cells) { continue }
                    let difference = b.cells.subtracting(a.cells)
                    let differenceMines = b.mines - a.mines
                    if differenceMines == 0 {
                        for u in difference where state[u] == .unknown {
                            changed = true
                            openCell(u)
                        }
                    } else if differenceMines == difference.count {
                        for u in difference where state[u] == .unknown {
                            state[u] = .mine
                            changed = true
                        }
                    }
                }
                if changed { break }
            }
            if changed { continue }

            // ukupan broj: preostale mine prema preostalim nepoznatim poljima
            var unknownCells: [Int] = []
            var knownMines = 0
            for i in 0..<total {
                if state[i] == .unknown { unknownCells.append(i) } else if state[i] == .mine { knownMines += 1 }
            }
            let remainingMines = mines.count - knownMines
            if !unknownCells.isEmpty {
                if remainingMines == 0 {
                    for u in unknownCells where state[u] == .unknown {
                        changed = true
                        openCell(u)
                    }
                } else if remainingMines == unknownCells.count {
                    for u in unknownCells {
                        state[u] = .mine
                        changed = true
                    }
                }
            }
        }

        for i in 0..<total where !mines.contains(i) && state[i] != .safe { return false }
        return true
    }

    static func makeLayout(level: MinesweeperLevel, safe: Int, timeBudget: TimeInterval = 2) -> MinesLayout {
        var generator = SystemRandomNumberGenerator()
        return makeLayout(rows: level.rows, cols: level.cols, mineCount: level.mines, safe: safe,
                          timeBudget: timeBudget, using: &generator)
    }

    /// Mine se postavljaju nakon prvog dodira, tako da je on (i njegovi susjedi) siguran i, ako ide,
    /// da se cijela ploča može riješiti logikom. Ako se u roku `timeBudget` ne nađe takva, uzima se bilo koja.
    static func makeLayout<G: RandomNumberGenerator>(rows: Int, cols: Int, mineCount: Int, safe: Int,
                                                     timeBudget: TimeInterval = 2,
                                                     using generator: inout G) -> MinesLayout {
        let geometry = MinesGeometry(rows: rows, cols: cols)
        let safeSet = Set([safe] + geometry.neighbours[safe])
        let pool = (0..<rows * cols).filter { !safeSet.contains($0) }
        let count = min(mineCount, pool.count)

        func sample(_ g: inout G) -> Set<Int> {
            var p = pool
            for k in 0..<count {
                p.swapAt(k, Int.random(in: k..<p.count, using: &g))
            }
            return Set(p[0..<count])
        }

        let deadline = Date().addingTimeInterval(timeBudget)
        while Date() < deadline {
            let candidate = sample(&generator)
            let counts = adjacency(mines: candidate, geometry: geometry)
            if isNoGuess(mines: candidate, adjacency: counts, start: safe, geometry: geometry) {
                return MinesLayout(mines: candidate, adjacency: counts, mayNeedGuess: false)
            }
        }
        let fallback = sample(&generator)
        return MinesLayout(mines: fallback, adjacency: adjacency(mines: fallback, geometry: geometry),
                           mayNeedGuess: true)
    }
}

/// Spremljena nedovršena partija.
struct MinesweeperSnapshot: Codable, Equatable {
    var level: MinesweeperLevel
    var cells: [MinesweeperModel.Cell]
    var mineCount: Int
    var flags: Int
    var revealedCount: Int
    var isFirstMove: Bool
    var mayNeedGuess: Bool
    var elapsed: TimeInterval
}

/// Stanje jedne partije Minolovca.
@Observable
final class MinesweeperModel {
    struct Cell: Equatable, Codable {
        var isMine = false
        var adjacent = 0
        var isRevealed = false
        var isFlagged = false
    }

    enum Outcome: Equatable {
        case won
        case lost(exploded: Int)
    }

    private(set) var level: MinesweeperLevel
    private(set) var cells: [Cell]
    private(set) var mineCount: Int
    private(set) var flags = 0
    private(set) var revealedCount = 0
    private(set) var isFirstMove = true
    private(set) var mayNeedGuess = false
    private(set) var outcome: Outcome?
    private(set) var finishTime: TimeInterval?
    /// Raste uz svaku radnju; prikaz po njemu daje haptiku.
    private(set) var moves = 0
    let timer: GameTimer

    private var geometry: MinesGeometry

    init(level: MinesweeperLevel = .easy, timer: GameTimer = GameTimer()) {
        self.level = level
        self.timer = timer
        self.mineCount = level.mines
        self.cells = Array(repeating: Cell(), count: level.rows * level.cols)
        self.geometry = MinesGeometry(rows: level.rows, cols: level.cols)
    }

    var rows: Int { level.rows }
    var cols: Int { level.cols }
    var minesLeft: Int { mineCount - flags }
    var isOver: Bool { outcome != nil }

    /// Stanje za spremanje; nil kad nema što spremiti (igra je gotova ili još nije dirnuta).
    var snapshot: MinesweeperSnapshot? {
        guard !isOver, !(isFirstMove && flags == 0) else { return nil }
        return MinesweeperSnapshot(level: level, cells: cells, mineCount: mineCount, flags: flags,
                                   revealedCount: revealedCount, isFirstMove: isFirstMove,
                                   mayNeedGuess: mayNeedGuess, elapsed: timer.elapsed())
    }

    /// Vraća spremljenu partiju; false ako spremljeni podaci nisu valjani.
    @discardableResult
    func restore(_ snapshot: MinesweeperSnapshot) -> Bool {
        let level = snapshot.level
        guard snapshot.cells.count == level.rows * level.cols,
              snapshot.cells.filter(\.isMine).count == (snapshot.isFirstMove ? 0 : snapshot.mineCount),
              snapshot.cells.filter(\.isRevealed).count == snapshot.revealedCount,
              snapshot.cells.filter(\.isFlagged).count == snapshot.flags
        else { return false }
        self.level = level
        geometry = MinesGeometry(rows: level.rows, cols: level.cols)
        cells = snapshot.cells
        mineCount = snapshot.mineCount
        flags = snapshot.flags
        revealedCount = snapshot.revealedCount
        isFirstMove = snapshot.isFirstMove
        mayNeedGuess = snapshot.mayNeedGuess
        outcome = nil
        finishTime = nil
        timer.restore(elapsed: snapshot.elapsed)
        moves += 1
        return true
    }

    /// Pogrešno postavljena zastavica prikazuje se tek kad je igra izgubljena.
    func isWrongFlag(_ i: Int) -> Bool {
        guard case .lost = outcome else { return false }
        return cells[i].isFlagged && !cells[i].isMine
    }

    func newGame(level newLevel: MinesweeperLevel? = nil) {
        level = newLevel ?? level
        geometry = MinesGeometry(rows: level.rows, cols: level.cols)
        mineCount = level.mines
        cells = Array(repeating: Cell(), count: level.rows * level.cols)
        flags = 0
        revealedCount = 0
        isFirstMove = true
        mayNeedGuess = false
        outcome = nil
        finishTime = nil
        timer.reset()
        moves += 1
    }

    /// Otkriva polje. Na prvi dodir se postavljaju mine; `layout` se može dati unaprijed
    /// (prikaz ga izračuna u pozadini), inače se računa ovdje.
    func reveal(_ i: Int, layout: MinesLayout? = nil) {
        guard !isOver, cells.indices.contains(i), !cells[i].isFlagged, !cells[i].isRevealed else { return }

        if isFirstMove {
            apply(layout ?? MinesweeperLogic.makeLayout(level: level, safe: i))
            isFirstMove = false
            timer.start()
        }
        moves += 1

        if cells[i].isMine {
            lose(at: i)
            return
        }
        flood(from: i)
        checkWin()
    }

    /// Postavlja ili skida zastavicu. Zastavica prije prvog dodira pokreće mjerač.
    func toggleFlag(_ i: Int) {
        guard !isOver, cells.indices.contains(i), !cells[i].isRevealed else { return }
        if !timer.hasStarted && isFirstMove { timer.start() }
        cells[i].isFlagged.toggle()
        flags += cells[i].isFlagged ? 1 : -1
        moves += 1
    }

    /// Igra je (ne)aktivna: na ekranu, bez prozorčića i u prvom planu.
    func setActive(_ active: Bool) {
        if active, !isOver { timer.resume() } else { timer.pause() }
    }

    // MARK: Privatno

    private func apply(_ layout: MinesLayout) {
        for i in cells.indices {
            cells[i].isMine = layout.mines.contains(i)
            cells[i].adjacent = max(0, layout.adjacency[i])
        }
        mineCount = layout.mines.count
        mayNeedGuess = layout.mayNeedGuess
    }

    private func flood(from start: Int) {
        var stack = [start]
        while let i = stack.popLast() {
            if cells[i].isRevealed || cells[i].isFlagged { continue }
            cells[i].isRevealed = true
            revealedCount += 1
            if cells[i].adjacent == 0 {
                for n in geometry.neighbours[i] where !cells[n].isRevealed { stack.append(n) }
            }
        }
    }

    private func lose(at hit: Int) {
        timer.pause()
        finishTime = timer.elapsed()
        for i in cells.indices where cells[i].isMine && !cells[i].isFlagged { cells[i].isRevealed = true }
        outcome = .lost(exploded: hit)
    }

    private func checkWin() {
        guard revealedCount == rows * cols - mineCount else { return }
        timer.pause()
        finishTime = timer.elapsed()
        for i in cells.indices where cells[i].isMine { cells[i].isFlagged = true }
        flags = mineCount
        outcome = .won
    }
}
