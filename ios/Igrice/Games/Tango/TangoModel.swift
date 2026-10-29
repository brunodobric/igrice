import Foundation
import Observation

/// Znak u polju: X (sunce u web verziji) ili O (mjesec).
enum TangoMark: Equatable, Codable {
    case x, o

    /// Mjesto u brojačima po redu i stupcu.
    var slot: Int { self == .x ? 0 : 1 }
}

/// Veza između dva susjedna polja: `=` znači ista, `×` različita.
enum TangoRelation: Equatable, Codable {
    case same, different
}

/// Neuređen par polja, da je ključ isti u oba smjera (`conKey` u index.html).
struct TangoPair: Hashable, Codable {
    let a: Int
    let b: Int

    init(_ first: Int, _ second: Int) {
        a = min(first, second)
        b = max(first, second)
    }
}

struct TangoLink: Equatable, Codable {
    let pair: TangoPair
    let relation: TangoRelation
}

struct TangoPuzzle: Equatable, Codable {
    var given: [TangoMark?]
    var links: [TangoLink]
}

/// Spremljena nedovršena partija.
struct TangoSnapshot: Codable, Equatable {
    var puzzle: TangoPuzzle
    var values: [TangoMark?]
    var elapsed: TimeInterval
}

struct TangoErrors: Equatable {
    var cells: Set<Int> = []
    var links: Set<Int> = []   // indeksi u `TangoPuzzle.links`
}

/// Generator, rješavač i provjere za Tango. Algoritmi su preneseni iz index.html.
enum TangoLogic {
    static let size = 6
    static let need = 3        // 3 X i 3 O u svakom redu i stupcu
    static let linkCount = 7
    static var cellCount: Int { size * size }

    typealias Board = [TangoMark?]
    typealias Constraints = [TangoPair: TangoRelation]

    static func index(_ row: Int, _ column: Int) -> Int { row * size + column }

    // MARK: Generiranje

    static func makePuzzle() -> TangoPuzzle {
        var generator = SystemRandomNumberGenerator()
        return makePuzzle(using: &generator)
    }

    /// Zagonetka: zadana polja i veze, rješiva samo logikom, bez pogađanja.
    static func makePuzzle<G: RandomNumberGenerator>(using generator: inout G) -> TangoPuzzle {
        let solution = generateSolution(using: &generator)

        var edges: [(Int, Int)] = []
        for r in 0..<size {
            for c in 0..<size {
                if c < size - 1 { edges.append((index(r, c), index(r, c + 1))) }
                if r < size - 1 { edges.append((index(r, c), index(r + 1, c))) }
            }
        }
        edges.shuffle(using: &generator)

        var constraints: Constraints = [:]
        for (a, b) in edges.prefix(linkCount) {
            constraints[TangoPair(a, b)] = solution[a] == solution[b] ? .same : .different
        }

        // Kreće se od potpunog rješenja i polja se skrivaju dok god ploču logika može dovršiti.
        // Svaki korak logicSolve je prisilan potez, pa je takva zagonetka jednoznačna i bez pogađanja.
        var givens = solution
        for i in (0..<cellCount).shuffled(using: &generator) {
            let saved = givens[i]
            givens[i] = nil
            if logicSolve(givens, constraints) == nil { givens[i] = saved }
        }

        let links = constraints
            .map { TangoLink(pair: $0.key, relation: $0.value) }
            .sorted { ($0.pair.a, $0.pair.b) < ($1.pair.a, $1.pair.b) }
        return TangoPuzzle(given: givens, links: links)
    }

    /// Nasumično potpuno ispunjena ploča koja zadovoljava pravila.
    static func generateSolution<G: RandomNumberGenerator>(using generator: inout G) -> Board {
        var board: Board = Array(repeating: nil, count: cellCount)
        var rowCount = Array(repeating: [0, 0], count: size)
        var columnCount = Array(repeating: [0, 0], count: size)

        func fill(_ position: Int, _ generator: inout G) -> Bool {
            if position == cellCount { return true }
            let r = position / size, c = position % size
            let options: [TangoMark] = Bool.random(using: &generator) ? [.x, .o] : [.o, .x]
            for v in options where canPlace(board, rowCount, columnCount, r, c, v) {
                board[position] = v
                rowCount[r][v.slot] += 1
                columnCount[c][v.slot] += 1
                if fill(position + 1, &generator) { return true }
                board[position] = nil
                rowCount[r][v.slot] -= 1
                columnCount[c][v.slot] -= 1
            }
            return false
        }

        _ = fill(0, &generator)
        return board
    }

    private static func canPlace(_ board: Board, _ rowCount: [[Int]], _ columnCount: [[Int]],
                                 _ r: Int, _ c: Int, _ v: TangoMark) -> Bool {
        if rowCount[r][v.slot] >= need { return false }
        if columnCount[c][v.slot] >= need { return false }
        if c >= 2, board[index(r, c - 1)] == v, board[index(r, c - 2)] == v { return false }
        if r >= 2, board[index(r - 1, c)] == v, board[index(r - 2, c)] == v { return false }
        return true
    }

    // MARK: Rješavač

    /// Bi li znak `v` u polju `i` sigurno prekršio pravilo na trenutnoj (djelomičnoj) ploči?
    /// Računaju se samo sigurni prekršaji, zato je potez "prisilan" i može se zaključiti bez pogađanja.
    static func isForbidden(_ board: Board, _ i: Int, _ v: TangoMark, _ constraints: Constraints) -> Bool {
        let r = i / size, c = i % size
        func at(_ row: Int, _ column: Int) -> TangoMark? {
            guard row >= 0, row < size, column >= 0, column < size else { return nil }
            return board[index(row, column)]
        }

        // u redu ili stupcu već ima 3 takva znaka
        var inRow = 0, inColumn = 0
        for k in 0..<size {
            if board[index(r, k)] == v { inRow += 1 }
            if board[index(k, c)] == v { inColumn += 1 }
        }
        if inRow >= need || inColumn >= need { return true }

        // tri ista u nizu (kao kraj, sredina ili početak trojke)
        if at(r, c - 1) == v, at(r, c - 2) == v { return true }
        if at(r, c - 1) == v, at(r, c + 1) == v { return true }
        if at(r, c + 1) == v, at(r, c + 2) == v { return true }
        if at(r - 1, c) == v, at(r - 2, c) == v { return true }
        if at(r - 1, c) == v, at(r + 1, c) == v { return true }
        if at(r + 1, c) == v, at(r + 2, c) == v { return true }

        // veze = i × prema već ispunjenim susjedima
        for (nr, nc) in [(r, c - 1), (r, c + 1), (r - 1, c), (r + 1, c)] {
            guard nr >= 0, nr < size, nc >= 0, nc < size else { continue }
            let j = index(nr, nc)
            guard let relation = constraints[TangoPair(i, j)], let neighbour = board[j] else { continue }
            if relation == .same ? neighbour != v : neighbour == v { return true }
        }
        return false
    }

    /// Rješava samo prisilnim potezima. Vraća ispunjenu ploču ako je zagonetka rješiva čistom logikom,
    /// a inače nil.
    static func logicSolve(_ givens: Board, _ constraints: Constraints) -> Board? {
        var board = givens
        var changed = true
        while changed {
            changed = false
            for i in 0..<cellCount where board[i] == nil {
                let canX = !isForbidden(board, i, .x, constraints)
                let canO = !isForbidden(board, i, .o, constraints)
                if !canX && !canO { return nil }   // proturječje
                if canX != canO {
                    board[i] = canX ? .x : .o
                    changed = true
                }
            }
        }
        return board.allSatisfy { $0 != nil } ? board : nil
    }

    // MARK: Provjera ploče

    static func errors(values: Board, links: [TangoLink]) -> TangoErrors {
        var result = TangoErrors()

        // previše istih znakova u redu ili stupcu
        for line in 0..<size {
            for isRow in [true, false] {
                let cells = (0..<size).map { isRow ? index(line, $0) : index($0, line) }
                for v in [TangoMark.x, .o] where cells.filter({ values[$0] == v }).count > need {
                    for cell in cells where values[cell] == v { result.cells.insert(cell) }
                }
            }
        }

        // tri ista u nizu
        for r in 0..<size {
            for c in 0...(size - 3) {
                let trio = [index(r, c), index(r, c + 1), index(r, c + 2)]
                if let a = values[trio[0]], values[trio[1]] == a, values[trio[2]] == a { result.cells.formUnion(trio) }
            }
        }
        for c in 0..<size {
            for r in 0...(size - 3) {
                let trio = [index(r, c), index(r + 1, c), index(r + 2, c)]
                if let a = values[trio[0]], values[trio[1]] == a, values[trio[2]] == a { result.cells.formUnion(trio) }
            }
        }

        // prekršene veze (samo kad su oba polja ispunjena)
        for (n, link) in links.enumerated() {
            guard let va = values[link.pair.a], let vb = values[link.pair.b] else { continue }
            if link.relation == .same ? va != vb : va == vb {
                result.links.insert(n)
                result.cells.insert(link.pair.a)
                result.cells.insert(link.pair.b)
            }
        }
        return result
    }

    static func isSolved(values: Board, links: [TangoLink]) -> Bool {
        guard values.allSatisfy({ $0 != nil }) else { return false }
        for line in 0..<size {
            let row = (0..<size).filter { values[index(line, $0)] == .x }.count
            let column = (0..<size).filter { values[index($0, line)] == .x }.count
            if row != need || column != need { return false }
        }
        for r in 0..<size {
            for c in 0...(size - 3) where values[index(r, c)] == values[index(r, c + 1)]
                && values[index(r, c)] == values[index(r, c + 2)] { return false }
        }
        for c in 0..<size {
            for r in 0...(size - 3) where values[index(r, c)] == values[index(r + 1, c)]
                && values[index(r, c)] == values[index(r + 2, c)] { return false }
        }
        for link in links {
            let same = values[link.pair.a] == values[link.pair.b]
            if link.relation == .same ? !same : same { return false }
        }
        return true
    }
}

/// Stanje jedne partije Tanga.
@Observable
final class TangoModel {
    private(set) var puzzle: TangoPuzzle
    private(set) var values: [TangoMark?]
    private(set) var isSolved = false
    private(set) var solveTime: TimeInterval?
    /// Raste uz svaku promjenu ploče; prikaz po njemu odgađa isticanje grešaka.
    private(set) var edits = 0
    let timer: GameTimer

    /// Bez zagonetke model ostaje prazan (`isReady` je false) dok se ne pozove `newPuzzle` ili `restore`,
    /// da se generiranje ne ponavlja pri svakom stvaranju prikaza.
    init(puzzle: TangoPuzzle? = nil, timer: GameTimer = GameTimer()) {
        let start = puzzle ?? TangoPuzzle(given: [], links: [])
        self.puzzle = start
        self.values = start.given
        self.timer = timer
    }

    var isReady: Bool { !values.isEmpty }
    var filledCount: Int { values.filter { $0 != nil }.count }
    var errors: TangoErrors {
        isSolved || !isReady ? TangoErrors() : TangoLogic.errors(values: values, links: puzzle.links)
    }

    /// Stanje za spremanje; nil kad nema što spremiti (nije spremno ili je riješeno).
    var snapshot: TangoSnapshot? {
        guard isReady, !isSolved else { return nil }
        return TangoSnapshot(puzzle: puzzle, values: values, elapsed: timer.elapsed())
    }

    /// Vraća spremljenu partiju; false ako spremljeni podaci nisu valjani.
    @discardableResult
    func restore(_ snapshot: TangoSnapshot) -> Bool {
        let count = TangoLogic.cellCount
        guard snapshot.puzzle.given.count == count, snapshot.values.count == count,
              snapshot.puzzle.links.allSatisfy({ $0.pair.a >= 0 && $0.pair.a < $0.pair.b && $0.pair.b < count }),
              (0..<count).allSatisfy({ snapshot.puzzle.given[$0] == nil || snapshot.values[$0] == snapshot.puzzle.given[$0] })
        else { return false }
        puzzle = snapshot.puzzle
        values = snapshot.values
        isSolved = false
        solveTime = nil
        timer.restore(elapsed: snapshot.elapsed)
        edits += 1
        return true
    }

    /// Dodir: prazno → X → O → prazno.
    func tap(_ i: Int) {
        guard values.indices.contains(i) else { return }
        switch values[i] {
        case nil: place(i, .x)
        case .x: place(i, .o)
        case .o: place(i, nil)
        }
    }

    /// Dugi pritisak: odmah O, a ponovno O → prazno.
    func toggleMoon(_ i: Int) {
        guard values.indices.contains(i) else { return }
        place(i, values[i] == .o ? nil : .o)
    }

    /// Briše sve osim zadanih polja; mjerač se ne dira.
    func clear() {
        guard !isSolved else { return }
        for i in values.indices where puzzle.given[i] == nil { values[i] = nil }
        edits += 1
    }

    func newPuzzle() {
        puzzle = TangoLogic.makePuzzle()
        values = puzzle.given
        isSolved = false
        solveTime = nil
        timer.reset()
        edits += 1
    }

    /// Igra je (ne)aktivna: na ekranu, bez prozorčića i u prvom planu.
    func setActive(_ active: Bool) {
        if active, !isSolved { timer.resume() } else { timer.pause() }
    }

    private func place(_ i: Int, _ mark: TangoMark?) {
        guard !isSolved, puzzle.given[i] == nil else { return }
        timer.start()
        values[i] = mark
        edits += 1
        if TangoLogic.isSolved(values: values, links: puzzle.links) {
            isSolved = true
            timer.pause()
            solveTime = timer.elapsed()
        }
    }
}
