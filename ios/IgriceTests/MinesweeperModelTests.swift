import XCTest
@testable import Igrice

final class MinesweeperModelTests: XCTestCase {
    private func layout(_ mines: Set<Int>, level: MinesweeperLevel = .easy) -> MinesLayout {
        let geometry = MinesGeometry(rows: level.rows, cols: level.cols)
        return MinesLayout(mines: mines, adjacency: MinesweeperLogic.adjacency(mines: mines, geometry: geometry),
                           mayNeedGuess: false)
    }

    // MARK: Geometrija i brojevi

    func testNeighbourCounts() {
        let geometry = MinesGeometry(rows: 8, cols: 8)
        XCTAssertEqual(geometry.neighbours[0].count, 3)      // kut
        XCTAssertEqual(geometry.neighbours[1].count, 5)      // rub
        XCTAssertEqual(geometry.neighbours[9].count, 8)      // sredina
    }

    func testAdjacencyCountsNeighbouringMines() {
        let geometry = MinesGeometry(rows: 8, cols: 8)
        let counts = MinesweeperLogic.adjacency(mines: [9, 10], geometry: geometry)
        XCTAssertEqual(counts[0], 1)
        XCTAssertEqual(counts[1], 2)
        XCTAssertEqual(counts[9], -1)
        XCTAssertEqual(counts[63], 0)
    }

    // MARK: Rješivost

    func testSingleMineInCornerIsSolvableByLogic() {
        let geometry = MinesGeometry(rows: 5, cols: 5)
        let mines: Set<Int> = [24]
        let counts = MinesweeperLogic.adjacency(mines: mines, geometry: geometry)
        XCTAssertTrue(MinesweeperLogic.isNoGuess(mines: mines, adjacency: counts, start: 0, geometry: geometry))
    }

    func testFiftyFiftyNeedsGuessing() {
        // 2×2 s jednom minom: iz kuta se ne može znati koje je od tri preostalih polja mina.
        let geometry = MinesGeometry(rows: 2, cols: 2)
        let mines: Set<Int> = [3]
        let counts = MinesweeperLogic.adjacency(mines: mines, geometry: geometry)
        XCTAssertFalse(MinesweeperLogic.isNoGuess(mines: mines, adjacency: counts, start: 0, geometry: geometry))
    }

    // MARK: Generator

    func testGeneratedLayoutKeepsFirstClickSafeAndIsConsistent() {
        for seed in 1...5 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let safe = 27
            let layout = MinesweeperLogic.makeLayout(rows: 8, cols: 8, mineCount: 10, safe: safe,
                                                     timeBudget: 3, using: &generator)
            let geometry = MinesGeometry(rows: 8, cols: 8)
            let safeZone = Set([safe] + geometry.neighbours[safe])

            XCTAssertEqual(layout.mines.count, 10, "seed \(seed)")
            XCTAssertTrue(layout.mines.isDisjoint(with: safeZone), "seed \(seed)")
            XCTAssertEqual(layout.adjacency, MinesweeperLogic.adjacency(mines: layout.mines, geometry: geometry))
            if !layout.mayNeedGuess {
                XCTAssertTrue(MinesweeperLogic.isNoGuess(mines: layout.mines, adjacency: layout.adjacency,
                                                         start: safe, geometry: geometry), "seed \(seed)")
            }
        }
    }

    func testLayoutWithTooManyMinesIsCappedByFreeCells() {
        var generator = SeededGenerator(seed: 1)
        let layout = MinesweeperLogic.makeLayout(rows: 3, cols: 3, mineCount: 50, safe: 4,
                                                 timeBudget: 0.1, using: &generator)
        XCTAssertTrue(layout.mines.isEmpty)   // sva polja su u sigurnoj zoni prvog dodira
    }

    // MARK: Model

    func testFirstRevealNeverHitsMine() {
        for _ in 0..<3 {
            let model = MinesweeperModel()
            model.reveal(27)
            XCTAssertFalse(model.cells[27].isMine)
            XCTAssertTrue(model.cells[27].isRevealed)
            XCTAssertEqual(model.cells.filter(\.isMine).count, 10)
            XCTAssertTrue(model.timer.isRunning)
        }
    }

    func testRevealFloodsEmptyAreaAndWins() {
        let model = MinesweeperModel()
        model.reveal(0, layout: layout([63]))
        XCTAssertEqual(model.outcome, .won)
        XCTAssertEqual(model.revealedCount, 63)
        XCTAssertEqual(model.flags, model.mineCount)     // preostale mine se same označe
        XCTAssertEqual(model.minesLeft, 0)
        XCTAssertFalse(model.timer.isRunning)
        XCTAssertNotNil(model.finishTime)
    }

    func testHittingMineLosesAndRevealsMines() {
        let model = MinesweeperModel()
        model.reveal(0, layout: layout([10, 63]))
        XCTAssertNil(model.outcome)

        model.reveal(10)
        XCTAssertEqual(model.outcome, .lost(exploded: 10))
        XCTAssertTrue(model.cells[10].isRevealed)
        XCTAssertTrue(model.cells[63].isRevealed)
        XCTAssertFalse(model.timer.isRunning)

        model.reveal(20)   // nakon kraja se ne otvara ništa
        XCTAssertFalse(model.cells[20].isRevealed)
    }

    func testFlagsCountAndBlockReveal() {
        let model = MinesweeperModel()
        model.reveal(0, layout: layout([10, 63]))

        model.toggleFlag(10)
        XCTAssertEqual(model.flags, 1)
        XCTAssertEqual(model.minesLeft, 1)
        model.reveal(10)                                 // označeno polje se ne otvara
        XCTAssertNil(model.outcome)
        XCTAssertFalse(model.cells[10].isRevealed)

        model.toggleFlag(10)
        XCTAssertEqual(model.flags, 0)
    }

    func testRevealedCellCannotBeFlagged() {
        let model = MinesweeperModel()
        model.reveal(0, layout: layout([63]))
        model.toggleFlag(0)
        XCTAssertFalse(model.cells[0].isFlagged)
    }

    func testWrongFlagsAreShownOnlyAfterLoss() {
        let model = MinesweeperModel()
        model.reveal(0, layout: layout([10, 63]))
        model.toggleFlag(20)                              // pogrešna zastavica
        XCTAssertFalse(model.isWrongFlag(20))
        model.reveal(10)
        XCTAssertTrue(model.isWrongFlag(20))
    }

    func testFlagBeforeFirstMoveStartsTimer() {
        let model = MinesweeperModel()
        model.toggleFlag(5)
        XCTAssertTrue(model.timer.isRunning)
        XCTAssertTrue(model.isFirstMove)
    }

    func testNewGameResetsAndSwitchesLevel() {
        let model = MinesweeperModel()
        model.reveal(0, layout: layout([10, 63]))
        model.newGame(level: .hard)
        XCTAssertEqual(model.level, .hard)
        XCTAssertEqual(model.cells.count, 256)
        XCTAssertEqual(model.mineCount, 50)
        XCTAssertTrue(model.isFirstMove)
        XCTAssertNil(model.outcome)
        XCTAssertFalse(model.timer.hasStarted)
    }

    func testInactiveGamePausesTimer() {
        let model = MinesweeperModel()
        model.reveal(0, layout: layout([10, 63]))
        XCTAssertTrue(model.timer.isRunning)
        model.setActive(false)
        XCTAssertFalse(model.timer.isRunning)
        model.setActive(true)
        XCTAssertTrue(model.timer.isRunning)
    }
}
