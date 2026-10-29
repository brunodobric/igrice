import Observation

/// Igrač u Križić Kružiću: Igrač 1 je X, Igrač 2 je O.
enum Player: Equatable {
    case x, o

    var other: Player { self == .x ? .o : .x }
    var name: String { self == .x ? "Igrač 1 (X)" : "Igrač 2 (O)" }
}

enum TicTacToeOutcome: Equatable {
    case win(Player, line: [Int])
    case draw
}

/// Pravila i stanje igre, bez ikakvog prikaza. Logika je ista kao u index.html.
@Observable
final class TicTacToeModel {
    static let wins = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    private(set) var cells: [Player?] = Array(repeating: nil, count: 9)
    private(set) var current: Player = .x
    private(set) var outcome: TicTacToeOutcome?
    private(set) var scoreX = 0
    private(set) var scoreO = 0
    private(set) var scoreDraws = 0

    var isOver: Bool { outcome != nil }

    /// Postavlja znak trenutnog igrača; zauzeto polje i završena igra se ignoriraju.
    func play(_ index: Int) {
        guard !isOver, cells.indices.contains(index), cells[index] == nil else { return }
        cells[index] = current

        if let result = evaluate() {
            outcome = result
            switch result {
            case .win(.x, _): scoreX += 1
            case .win(.o, _): scoreO += 1
            case .draw: scoreDraws += 1
            }
        } else {
            current = current.other
        }
    }

    /// Nova partija: prazna ploča, prvi je opet X; bodovi ostaju.
    func newGame() {
        cells = Array(repeating: nil, count: 9)
        current = .x
        outcome = nil
    }

    /// Resetira bodove i počinje novu partiju.
    func resetScores() {
        scoreX = 0
        scoreO = 0
        scoreDraws = 0
        newGame()
    }

    private func evaluate() -> TicTacToeOutcome? {
        for line in Self.wins {
            if let player = cells[line[0]], player == cells[line[1]], player == cells[line[2]] {
                return .win(player, line: line)
            }
        }
        return cells.allSatisfy { $0 != nil } ? .draw : nil
    }
}
