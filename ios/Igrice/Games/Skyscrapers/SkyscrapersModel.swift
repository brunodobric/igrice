import Foundation
import Observation

/// Težina: Lagano (svi tragovi), Klasično (rješivo logikom), Pro (jedno rješenje, može tražiti pogađanje).
enum SkyscrapersMode: String, CaseIterable, Sendable, Codable {
    case easy, classic, pro

    var label: String {
        switch self {
        case .easy: "Lagano"
        case .classic: "Klasično"
        case .pro: "Pro"
        }
    }
}

enum SkyscrapersSide: CaseIterable, Sendable {
    case top, bottom, left, right
}

/// Tragovi uz rub: koliko se nebodera vidi iz tog smjera; 0 znači da trag nije prikazan.
struct SkyscrapersClues: Equatable, Sendable, Codable {
    var top: [Int]
    var bottom: [Int]
    var left: [Int]
    var right: [Int]

    subscript(side: SkyscrapersSide) -> [Int] {
        get {
            switch side {
            case .top: top
            case .bottom: bottom
            case .left: left
            case .right: right
            }
        }
        set {
            switch side {
            case .top: top = newValue
            case .bottom: bottom = newValue
            case .left: left = newValue
            case .right: right = newValue
            }
        }
    }
}

/// Spremljena nedovršena partija.
struct SkyscrapersSnapshot: Codable, Equatable {
    var mode: SkyscrapersMode
    var clues: SkyscrapersClues
    var values: [Int]
    var elapsed: TimeInterval
}

struct SkyscrapersClueID: Hashable {
    let side: SkyscrapersSide
    let index: Int
}

struct SkyscrapersErrors: Equatable {
    var cells: Set<Int> = []
    var clues: Set<SkyscrapersClueID> = []
}

/// Generator, rješavač i provjere za Nebodere. Algoritmi su preneseni iz index.html.
enum SkyscrapersLogic {
    static let size = 5

    /// Sve permutacije visina 1 do 5, za rješavač po linijama.
    static let permutations: [[Int]] = {
        var result: [[Int]] = []
        func permute(_ accumulated: [Int], _ rest: [Int]) {
            if rest.isEmpty { result.append(accumulated); return }
            for k in rest.indices {
                var remaining = rest
                let value = remaining.remove(at: k)
                permute(accumulated + [value], remaining)
            }
        }
        permute([], Array(1...size))
        return result
    }()

    static func index(_ row: Int, _ column: Int) -> Int { row * size + column }

    /// Koliko se nebodera vidi gledajući duž linije visina.
    static func visible<S: Sequence>(_ line: S) -> Int where S.Element == Int {
        var tallest = 0, count = 0
        for height in line where height > tallest {
            tallest = height
            count += 1
        }
        return count
    }

    static func row(_ board: [Int], _ r: Int) -> [Int] { (0..<size).map { board[index(r, $0)] } }
    static func column(_ board: [Int], _ c: Int) -> [Int] { (0..<size).map { board[index($0, c)] } }

    // MARK: Generiranje

    static func makePuzzle(mode: SkyscrapersMode) -> SkyscrapersClues {
        var generator = SystemRandomNumberGenerator()
        return makePuzzle(mode: mode, using: &generator)
    }

    /// Zagonetka s najmanje tragova koje način dopušta. Lagano: svi tragovi. Klasično: mora ostati rješiva
    /// logikom (to je automatski i jednoznačno). Pro: dovoljno je jedno rješenje.
    static func makePuzzle<G: RandomNumberGenerator>(mode: SkyscrapersMode, using generator: inout G) -> SkyscrapersClues {
        if mode == .easy {
            var clues = computeClues(generateSolution(using: &generator))
            for _ in 0..<400 {
                clues = computeClues(generateSolution(using: &generator))
                if logicSolve(clues) { return clues }
            }
            return clues   // zamjenski slučaj (vrlo rijedak)
        }

        let classic = mode == .classic
        func solvable(_ clues: SkyscrapersClues) -> Bool {
            classic ? logicSolve(clues) : countSolutions(clues, limit: 2) == 1
        }

        var full: SkyscrapersClues?
        for _ in 0..<400 {
            let candidate = computeClues(generateSolution(using: &generator))
            if solvable(candidate) { full = candidate; break }
        }
        var clues = full ?? computeClues(generateSolution(using: &generator))

        var positions: [SkyscrapersClueID] = []
        for i in 0..<size {
            for side in SkyscrapersSide.allCases { positions.append(SkyscrapersClueID(side: side, index: i)) }
        }
        positions.shuffle(using: &generator)
        for position in positions {
            let saved = clues[position.side][position.index]
            clues[position.side][position.index] = 0
            if !solvable(clues) { clues[position.side][position.index] = saved }   // potreban, vraća se
        }
        return clues
    }

    /// Nasumični latinski kvadrat: svaki red i stupac je permutacija 1 do 5.
    static func generateSolution<G: RandomNumberGenerator>(using generator: inout G) -> [Int] {
        var board = Array(repeating: 0, count: size * size)
        var rowUsed = Array(repeating: Array(repeating: false, count: size + 1), count: size)
        var columnUsed = rowUsed

        func fill(_ position: Int, _ generator: inout G) -> Bool {
            if position == size * size { return true }
            let r = position / size, c = position % size
            for v in Array(1...size).shuffled(using: &generator) {
                if rowUsed[r][v] || columnUsed[c][v] { continue }
                board[position] = v
                rowUsed[r][v] = true
                columnUsed[c][v] = true
                if fill(position + 1, &generator) { return true }
                board[position] = 0
                rowUsed[r][v] = false
                columnUsed[c][v] = false
            }
            return false
        }

        _ = fill(0, &generator)
        return board
    }

    /// Tragovi sa svih strana potpunog rješenja.
    static func computeClues(_ solution: [Int]) -> SkyscrapersClues {
        var clues = SkyscrapersClues(top: [], bottom: [], left: [], right: [])
        for i in 0..<size {
            let col = column(solution, i), rw = row(solution, i)
            clues.top.append(visible(col))
            clues.bottom.append(visible(col.reversed()))
            clues.left.append(visible(rw))
            clues.right.append(visible(rw.reversed()))
        }
        return clues
    }

    // MARK: Rješavači

    /// Broji rješenja koja odgovaraju tragovima, do `limit`.
    static func countSolutions(_ clues: SkyscrapersClues, limit: Int) -> Int {
        var board = Array(repeating: 0, count: size * size)
        var rowUsed = Array(repeating: Array(repeating: false, count: size + 1), count: size)
        var columnUsed = rowUsed
        var count = 0

        func fill(_ position: Int) {
            if count >= limit { return }
            if position == size * size { count += 1; return }
            let r = position / size, c = position % size
            for v in 1...size {
                if rowUsed[r][v] || columnUsed[c][v] { continue }
                board[position] = v
                rowUsed[r][v] = true
                columnUsed[c][v] = true
                var good = true
                if c == size - 1 {   // red r je gotov
                    let line = row(board, r)
                    if clues.left[r] != 0, visible(line) != clues.left[r] { good = false }
                    if good, clues.right[r] != 0, visible(line.reversed()) != clues.right[r] { good = false }
                }
                if good, r == size - 1 {   // stupac c je gotov
                    let line = column(board, c)
                    if clues.top[c] != 0, visible(line) != clues.top[c] { good = false }
                    if good, clues.bottom[c] != 0, visible(line.reversed()) != clues.bottom[c] { good = false }
                }
                if good { fill(position + 1) }
                board[position] = 0
                rowUsed[r][v] = false
                columnUsed[c][v] = false
                if count >= limit { return }
            }
        }

        fill(0)
        return count
    }

    /// Rješava samo logikom po linijama: u svakom redu i stupcu ostaju samo visine koje podržava
    /// neki raspored u skladu s kandidatima i tragovima. Nikad ne pogađa preko linija.
    /// Vraća true samo ako tako odredi cijelu ploču, tj. zagonetka se rješava bez pogađanja.
    static func logicSolve(_ clues: SkyscrapersClues) -> Bool {
        // kandidati po polju kao bitovi: bit v je postavljen ako je visina v još moguća
        let all: UInt8 = 0b0011_1110
        var candidates = Array(repeating: all, count: size * size)

        var changed = true
        while changed {
            changed = false
            for isRow in [true, false] {
                for i in 0..<size {
                    let cells = (0..<size).map { isRow ? index(i, $0) : index($0, i) }
                    let front = isRow ? clues.left[i] : clues.top[i]
                    let back = isRow ? clues.right[i] : clues.bottom[i]
                    var allowed = Array(repeating: UInt8(0), count: size)
                    var any = false

                    for permutation in permutations {
                        var fits = true
                        for k in 0..<size where candidates[cells[k]] & (1 << UInt8(permutation[k])) == 0 {
                            fits = false
                            break
                        }
                        if !fits { continue }
                        if front != 0, visible(permutation) != front { continue }
                        if back != 0, visible(permutation.reversed()) != back { continue }
                        any = true
                        for k in 0..<size { allowed[k] |= 1 << UInt8(permutation[k]) }
                    }
                    if !any { return false }   // nema valjanog rasporeda: proturječje

                    for k in 0..<size {
                        let narrowed = candidates[cells[k]] & allowed[k]
                        if narrowed != candidates[cells[k]] {
                            candidates[cells[k]] = narrowed
                            changed = true
                        }
                        if narrowed == 0 { return false }
                    }
                }
            }
        }
        return candidates.allSatisfy { $0.nonzeroBitCount == 1 }
    }

    // MARK: Provjera ploče

    /// Duplikati u redu ili stupcu; trag je kriv tek kad je cijela linija popunjena.
    static func errors(values: [Int], clues: SkyscrapersClues) -> SkyscrapersErrors {
        var result = SkyscrapersErrors()

        for i in 0..<size {
            for isRow in [true, false] {
                let cells = (0..<size).map { isRow ? index(i, $0) : index($0, i) }
                var seen: [Int: [Int]] = [:]
                for cell in cells where values[cell] != 0 { seen[values[cell], default: []].append(cell) }
                for group in seen.values where group.count > 1 { result.cells.formUnion(group) }
            }
        }

        for r in 0..<size {
            let line = row(values, r)
            guard line.allSatisfy({ $0 != 0 }) else { continue }
            if clues.left[r] != 0, visible(line) != clues.left[r] {
                result.clues.insert(SkyscrapersClueID(side: .left, index: r))
            }
            if clues.right[r] != 0, visible(line.reversed()) != clues.right[r] {
                result.clues.insert(SkyscrapersClueID(side: .right, index: r))
            }
        }
        for c in 0..<size {
            let line = column(values, c)
            guard line.allSatisfy({ $0 != 0 }) else { continue }
            if clues.top[c] != 0, visible(line) != clues.top[c] {
                result.clues.insert(SkyscrapersClueID(side: .top, index: c))
            }
            if clues.bottom[c] != 0, visible(line.reversed()) != clues.bottom[c] {
                result.clues.insert(SkyscrapersClueID(side: .bottom, index: c))
            }
        }
        return result
    }

    static func isSolved(values: [Int], clues: SkyscrapersClues) -> Bool {
        guard values.allSatisfy({ $0 != 0 }) else { return false }
        for i in 0..<size {
            if Set(row(values, i)).count != size || Set(column(values, i)).count != size { return false }
        }
        for r in 0..<size {
            let line = row(values, r)
            if clues.left[r] != 0, visible(line) != clues.left[r] { return false }
            if clues.right[r] != 0, visible(line.reversed()) != clues.right[r] { return false }
        }
        for c in 0..<size {
            let line = column(values, c)
            if clues.top[c] != 0, visible(line) != clues.top[c] { return false }
            if clues.bottom[c] != 0, visible(line.reversed()) != clues.bottom[c] { return false }
        }
        return true
    }
}

/// Stanje jedne partije Nebodera.
@Observable
final class SkyscrapersModel {
    private(set) var mode: SkyscrapersMode
    /// nil dok se zagonetka još generira.
    private(set) var clues: SkyscrapersClues?
    private(set) var values = Array(repeating: 0, count: SkyscrapersLogic.size * SkyscrapersLogic.size)
    private(set) var isSolved = false
    private(set) var solveTime: TimeInterval?
    /// Raste uz svaku promjenu ploče; prikaz po njemu daje haptiku.
    private(set) var edits = 0
    let timer: GameTimer

    init(mode: SkyscrapersMode = .classic, clues: SkyscrapersClues? = nil, timer: GameTimer = GameTimer()) {
        self.mode = mode
        self.clues = clues
        self.timer = timer
    }

    var filledCount: Int { values.filter { $0 != 0 }.count }

    var errors: SkyscrapersErrors {
        guard let clues else { return SkyscrapersErrors() }
        return SkyscrapersLogic.errors(values: values, clues: clues)
    }

    /// Stanje za spremanje; nil kad nema što spremiti (nije spremno ili je riješeno).
    var snapshot: SkyscrapersSnapshot? {
        guard let clues, !isSolved else { return nil }
        return SkyscrapersSnapshot(mode: mode, clues: clues, values: values, elapsed: timer.elapsed())
    }

    /// Vraća spremljenu partiju; false ako spremljeni podaci nisu valjani.
    @discardableResult
    func restore(_ snapshot: SkyscrapersSnapshot) -> Bool {
        let size = SkyscrapersLogic.size
        let clues = snapshot.clues
        guard snapshot.values.count == size * size, snapshot.values.allSatisfy({ (0...size).contains($0) }),
              [clues.top, clues.bottom, clues.left, clues.right].allSatisfy({ $0.count == size && $0.allSatisfy { (0...size).contains($0) } })
        else { return false }
        self.clues = clues
        mode = snapshot.mode
        values = snapshot.values
        isSolved = false
        solveTime = nil
        timer.restore(elapsed: snapshot.elapsed)
        edits += 1
        return true
    }

    /// Nova zagonetka je spremna: prazna ploča, mjerač od nule.
    func start(_ newClues: SkyscrapersClues, mode newMode: SkyscrapersMode) {
        clues = newClues
        mode = newMode
        values = Array(repeating: 0, count: values.count)
        isSolved = false
        solveTime = nil
        timer.reset()
        edits += 1
    }

    /// Dodir povećava visinu (1 → 5 → prazno), dugi pritisak je smanjuje.
    func raise(_ i: Int) { cycle(i, by: 1) }
    func lower(_ i: Int) { cycle(i, by: -1) }

    func clear() {
        guard !isSolved else { return }
        values = Array(repeating: 0, count: values.count)
        edits += 1
    }

    /// Igra je (ne)aktivna: na ekranu, bez prozorčića i u prvom planu.
    func setActive(_ active: Bool) {
        if active, !isSolved { timer.resume() } else { timer.pause() }
    }

    private func cycle(_ i: Int, by step: Int) {
        guard let clues, !isSolved, values.indices.contains(i) else { return }
        let levels = SkyscrapersLogic.size + 1
        timer.start()
        values[i] = (values[i] + step + levels) % levels
        edits += 1
        if SkyscrapersLogic.isSolved(values: values, clues: clues) {
            isSolved = true
            timer.pause()
            solveTime = timer.elapsed()
        }
    }
}
