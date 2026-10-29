import XCTest
@testable import Igrice

final class TicTacToeModelTests: XCTestCase {
    private func play(_ moves: [Int], on model: TicTacToeModel = TicTacToeModel()) -> TicTacToeModel {
        moves.forEach { model.play($0) }
        return model
    }

    func testPlayersAlternateStartingWithX() {
        let model = play([0])
        XCTAssertEqual(model.cells[0], .x)
        XCTAssertEqual(model.current, .o)
        model.play(1)
        XCTAssertEqual(model.cells[1], .o)
        XCTAssertEqual(model.current, .x)
    }

    func testOccupiedCellIsIgnored() {
        let model = play([0, 0])
        XCTAssertEqual(model.cells[0], .x)
        XCTAssertEqual(model.current, .o)
    }

    func testEveryWinningLineWins() {
        for line in TicTacToeModel.wins {
            let others = (0..<9).filter { !line.contains($0) }
            // X igra liniju, O igra polja izvan nje (O nikad ne dobije tri u redu prije X-a).
            let model = play([line[0], others[0], line[1], others[1], line[2]])
            XCTAssertEqual(model.outcome, .win(.x, line: line), "linija \(line)")
            XCTAssertEqual(model.scoreX, 1)
        }
    }

    func testOCanWin() {
        let model = play([0, 3, 1, 4, 8, 5])
        XCTAssertEqual(model.outcome, .win(.o, line: [3, 4, 5]))
        XCTAssertEqual(model.scoreO, 1)
    }

    func testDraw() {
        // X O X / X O O / O X X
        let model = play([0, 1, 2, 4, 3, 5, 7, 6, 8])
        XCTAssertEqual(model.outcome, .draw)
        XCTAssertEqual(model.scoreDraws, 1)
    }

    func testNoMovesAfterGameOver() {
        let model = play([0, 3, 1, 4, 2])
        XCTAssertTrue(model.isOver)
        model.play(8)
        XCTAssertNil(model.cells[8])
        XCTAssertEqual(model.scoreX, 1)
    }

    func testNewGameKeepsScoresAndResetsBoard() {
        let model = play([0, 3, 1, 4, 2])
        model.newGame()
        XCTAssertEqual(model.cells, Array(repeating: nil, count: 9))
        XCTAssertEqual(model.current, .x)
        XCTAssertNil(model.outcome)
        XCTAssertEqual(model.scoreX, 1)
    }

    func testResetScores() {
        let model = play([0, 3, 1, 4, 2])
        model.resetScores()
        XCTAssertEqual(model.scoreX, 0)
        XCTAssertEqual(model.scoreO, 0)
        XCTAssertEqual(model.scoreDraws, 0)
        XCTAssertNil(model.outcome)
    }
}
