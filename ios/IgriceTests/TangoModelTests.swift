import XCTest
@testable import Igrice

final class TangoModelTests: XCTestCase {
    private let size = TangoLogic.size

    private func assertValid(_ board: TangoLogic.Board, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(board.allSatisfy { $0 != nil }, "ploča nije puna", file: file, line: line)
        XCTAssertTrue(TangoLogic.isSolved(values: board, links: []), "ploča krši pravila", file: file, line: line)
    }

    // MARK: Generator

    func testGeneratedSolutionsFollowTheRules() {
        for seed in 1...50 {
            var generator = SeededGenerator(seed: UInt64(seed))
            assertValid(TangoLogic.generateSolution(using: &generator))
        }
    }

    func testPuzzlesAreSolvableByLogicAndMatchTheirSolution() {
        for seed in 1...30 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let puzzle = TangoLogic.makePuzzle(using: &generator)
            XCTAssertEqual(puzzle.links.count, TangoLogic.linkCount, "seed \(seed)")

            let constraints = Dictionary(uniqueKeysWithValues: puzzle.links.map { ($0.pair, $0.relation) })
            guard let solved = TangoLogic.logicSolve(puzzle.given, constraints) else {
                return XCTFail("zagonetka nije rješiva logikom, seed \(seed)")
            }
            XCTAssertTrue(TangoLogic.isSolved(values: solved, links: puzzle.links), "seed \(seed)")
            for i in 0..<TangoLogic.cellCount where puzzle.given[i] != nil {
                XCTAssertEqual(solved[i], puzzle.given[i], "zadano polje promijenjeno, seed \(seed)")
            }
        }
    }

    func testPuzzleLinksAreBetweenNeighbours() {
        var generator = SeededGenerator(seed: 7)
        for link in TangoLogic.makePuzzle(using: &generator).links {
            let distance = link.pair.b - link.pair.a
            let sameRow = link.pair.a / size == link.pair.b / size
            XCTAssertTrue(distance == size || (distance == 1 && sameRow))
        }
    }

    // MARK: Rješavač

    func testEmptyBoardWithoutLinksNeedsGuessing() {
        let empty: TangoLogic.Board = Array(repeating: nil, count: TangoLogic.cellCount)
        XCTAssertNil(TangoLogic.logicSolve(empty, [:]))
    }

    func testForbiddenWhenLineAlreadyHasThree() {
        var board: TangoLogic.Board = Array(repeating: nil, count: TangoLogic.cellCount)
        for c in [0, 2, 4] { board[TangoLogic.index(0, c)] = .x }
        XCTAssertTrue(TangoLogic.isForbidden(board, TangoLogic.index(0, 5), .x, [:]))
        XCTAssertFalse(TangoLogic.isForbidden(board, TangoLogic.index(0, 5), .o, [:]))
    }

    func testForbiddenWhenItWouldMakeThreeInARow() {
        var board: TangoLogic.Board = Array(repeating: nil, count: TangoLogic.cellCount)
        board[TangoLogic.index(2, 0)] = .o
        board[TangoLogic.index(2, 1)] = .o
        XCTAssertTrue(TangoLogic.isForbidden(board, TangoLogic.index(2, 2), .o, [:]))   // kraj trojke

        board = Array(repeating: nil, count: TangoLogic.cellCount)
        board[TangoLogic.index(3, 1)] = .x
        board[TangoLogic.index(3, 3)] = .x
        XCTAssertTrue(TangoLogic.isForbidden(board, TangoLogic.index(3, 2), .x, [:]))   // sredina trojke
    }

    func testForbiddenByLinks() {
        var board: TangoLogic.Board = Array(repeating: nil, count: TangoLogic.cellCount)
        board[0] = .o
        let same: TangoLogic.Constraints = [TangoPair(0, 1): .same]
        XCTAssertTrue(TangoLogic.isForbidden(board, 1, .x, same))
        XCTAssertFalse(TangoLogic.isForbidden(board, 1, .o, same))

        let different: TangoLogic.Constraints = [TangoPair(0, 1): .different]
        XCTAssertTrue(TangoLogic.isForbidden(board, 1, .o, different))
        XCTAssertFalse(TangoLogic.isForbidden(board, 1, .x, different))
    }

    // MARK: Greške

    func testErrorsFlagThreeInARowAndBrokenLinks() {
        var board: TangoLogic.Board = Array(repeating: nil, count: TangoLogic.cellCount)
        for c in 0..<3 { board[TangoLogic.index(0, c)] = .x }
        board[TangoLogic.index(5, 0)] = .x
        board[TangoLogic.index(5, 1)] = .x
        let links = [TangoLink(pair: TangoPair(TangoLogic.index(5, 0), TangoLogic.index(5, 1)), relation: .different)]

        let errors = TangoLogic.errors(values: board, links: links)
        XCTAssertEqual(errors.cells, [0, 1, 2, TangoLogic.index(5, 0), TangoLogic.index(5, 1)])
        XCTAssertEqual(errors.links, [0])
    }

    func testErrorsFlagMoreThanThreeOfAKind() {
        var board: TangoLogic.Board = Array(repeating: nil, count: TangoLogic.cellCount)
        for c in [0, 1, 3, 4] { board[TangoLogic.index(0, c)] = .o }
        board[TangoLogic.index(0, 2)] = .x
        let errors = TangoLogic.errors(values: board, links: [])
        XCTAssertEqual(errors.cells, [0, 1, 3, 4])
    }

    // MARK: Model

    private func blankPuzzle(given: [Int: TangoMark] = [:]) -> TangoPuzzle {
        var cells: [TangoMark?] = Array(repeating: nil, count: TangoLogic.cellCount)
        for (i, mark) in given { cells[i] = mark }
        return TangoPuzzle(given: cells, links: [])
    }

    func testTapCyclesEmptyXOEmpty() {
        let model = TangoModel(puzzle: blankPuzzle())
        model.tap(0); XCTAssertEqual(model.values[0], .x)
        model.tap(0); XCTAssertEqual(model.values[0], .o)
        model.tap(0); XCTAssertNil(model.values[0])
    }

    func testLongPressTogglesMoon() {
        let model = TangoModel(puzzle: blankPuzzle())
        model.toggleMoon(3); XCTAssertEqual(model.values[3], .o)
        model.toggleMoon(3); XCTAssertNil(model.values[3])
    }

    func testGivenCellsCannotChangeAndClearKeepsThem() {
        let model = TangoModel(puzzle: blankPuzzle(given: [0: .x]))
        model.tap(0)
        model.toggleMoon(0)
        XCTAssertEqual(model.values[0], .x)

        model.tap(1)
        model.clear()
        XCTAssertEqual(model.values[0], .x)
        XCTAssertNil(model.values[1])
    }

    func testFirstMoveStartsTimerAndSolvingStopsIt() {
        var generator = SeededGenerator(seed: 11)
        let solution = TangoLogic.generateSolution(using: &generator)
        let model = TangoModel(puzzle: blankPuzzle())
        XCTAssertFalse(model.timer.isRunning)

        for (i, mark) in solution.enumerated() {
            model.tap(i)
            if mark == .o { model.tap(i) }
            if i == 0 { XCTAssertTrue(model.timer.isRunning) }
        }
        XCTAssertTrue(model.isSolved)
        XCTAssertFalse(model.timer.isRunning)
        XCTAssertNotNil(model.solveTime)

        model.tap(0)   // nakon rješenja se ploča ne mijenja
        XCTAssertEqual(model.values[0], solution[0])
    }

    func testInactiveGamePausesTimer() {
        let model = TangoModel(puzzle: blankPuzzle())
        model.setActive(true)
        XCTAssertFalse(model.timer.isRunning)   // još nije počela

        model.tap(0)
        XCTAssertTrue(model.timer.isRunning)
        model.setActive(false)
        XCTAssertFalse(model.timer.isRunning)
        model.setActive(true)
        XCTAssertTrue(model.timer.isRunning)
    }

    func testNewPuzzleResetsState() {
        let model = TangoModel(puzzle: blankPuzzle())
        model.tap(0)
        model.newPuzzle()
        XCTAssertEqual(model.values, model.puzzle.given)
        XCTAssertFalse(model.isSolved)
        XCTAssertFalse(model.timer.isRunning)
        XCTAssertFalse(model.timer.hasStarted)
    }

    // MARK: Spremanje

    func testSnapshotRoundTripRestoresPartialGame() throws {
        var generator = SeededGenerator(seed: 5)
        let puzzle = TangoLogic.makePuzzle(using: &generator)
        let model = TangoModel(puzzle: puzzle)
        let free = (0..<TangoLogic.cellCount).first { puzzle.given[$0] == nil }!
        model.tap(free)
        model.timer.restore(elapsed: 12)

        let data = try JSONEncoder().encode(try XCTUnwrap(model.snapshot))
        let loaded = try JSONDecoder().decode(TangoSnapshot.self, from: data)

        let restored = TangoModel()
        XCTAssertFalse(restored.isReady)
        XCTAssertTrue(restored.restore(loaded))
        XCTAssertTrue(restored.isReady)
        XCTAssertEqual(restored.puzzle, puzzle)
        XCTAssertEqual(restored.values, model.values)
        XCTAssertEqual(restored.timer.elapsed(), 12, accuracy: 0.001)
    }

    func testRestoreRejectsInvalidSnapshots() {
        let model = TangoModel()
        let tooShort = TangoSnapshot(puzzle: TangoPuzzle(given: [], links: []), values: [], elapsed: 0)
        XCTAssertFalse(model.restore(tooShort))

        var cells: [TangoMark?] = Array(repeating: nil, count: TangoLogic.cellCount)
        let badLink = TangoLink(pair: TangoPair(0, TangoLogic.cellCount), relation: .same)
        XCTAssertFalse(model.restore(TangoSnapshot(puzzle: TangoPuzzle(given: cells, links: [badLink]),
                                                   values: cells, elapsed: 0)))

        let given = cells
        cells[0] = .x                                       // vrijednost ne odgovara zadanom polju
        var withGiven = given
        withGiven[0] = .o
        XCTAssertFalse(model.restore(TangoSnapshot(puzzle: TangoPuzzle(given: withGiven, links: []),
                                                   values: cells, elapsed: 0)))
        XCTAssertFalse(model.isReady)
    }

    func testSnapshotExistsOnlyOnceModelIsReady() {
        var generator = SeededGenerator(seed: 11)
        let solution = TangoLogic.generateSolution(using: &generator)
        XCTAssertNotNil(TangoModel(puzzle: TangoPuzzle(given: solution, links: [])).snapshot)
        XCTAssertNil(TangoModel().snapshot)
    }
}
