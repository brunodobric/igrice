import XCTest
@testable import Igrice

final class SkyscrapersModelTests: XCTestCase {
    private let size = SkyscrapersLogic.size

    /// Cikličko rješenje: svaki red je prethodni pomaknut za jedno mjesto.
    private let cyclic: [Int] = [
        1, 2, 3, 4, 5,
        2, 3, 4, 5, 1,
        3, 4, 5, 1, 2,
        4, 5, 1, 2, 3,
        5, 1, 2, 3, 4
    ]

    private func assertLatinSquare(_ board: [Int], file: StaticString = #filePath, line: UInt = #line) {
        for i in 0..<size {
            XCTAssertEqual(Set(SkyscrapersLogic.row(board, i)), Set(1...size), "redak \(i)", file: file, line: line)
            XCTAssertEqual(Set(SkyscrapersLogic.column(board, i)), Set(1...size), "stupac \(i)", file: file, line: line)
        }
    }

    private func emptyClues() -> SkyscrapersClues {
        SkyscrapersClues(top: Array(repeating: 0, count: size), bottom: Array(repeating: 0, count: size),
                         left: Array(repeating: 0, count: size), right: Array(repeating: 0, count: size))
    }

    // MARK: Osnove

    func testVisibleCountsBuildingsNotHiddenByTaller() {
        XCTAssertEqual(SkyscrapersLogic.visible([1, 2, 3, 4, 5]), 5)
        XCTAssertEqual(SkyscrapersLogic.visible([5, 4, 3, 2, 1]), 1)
        XCTAssertEqual(SkyscrapersLogic.visible([2, 5, 3, 4, 1]), 2)
        XCTAssertEqual(SkyscrapersLogic.visible([3, 1, 4, 2, 5]), 3)
        XCTAssertEqual(SkyscrapersLogic.visible([1, 2, 3, 4, 5].reversed()), 1)
    }

    func testPermutationsAreAllOfOneToFive() {
        let perms = SkyscrapersLogic.permutations
        XCTAssertEqual(perms.count, 120)
        XCTAssertEqual(Set(perms).count, 120)
        XCTAssertTrue(perms.allSatisfy { Set($0) == Set(1...5) })
    }

    func testComputeCluesOfCyclicSolution() {
        let clues = SkyscrapersLogic.computeClues(cyclic)
        XCTAssertEqual(clues.left, [5, 4, 3, 2, 1])
        XCTAssertEqual(clues.right, [1, 2, 2, 2, 2])
        XCTAssertEqual(clues.top, [5, 4, 3, 2, 1])
        XCTAssertEqual(clues.bottom, [1, 2, 2, 2, 2])
    }

    func testGeneratedSolutionsAreLatinSquares() {
        for seed in 1...20 {
            var generator = SeededGenerator(seed: UInt64(seed))
            assertLatinSquare(SkyscrapersLogic.generateSolution(using: &generator))
        }
    }

    // MARK: Rješavači

    func testCountSolutionsWithFullCluesAndWithNone() {
        XCTAssertGreaterThanOrEqual(SkyscrapersLogic.countSolutions(emptyClues(), limit: 2), 2)

        var generator = SeededGenerator(seed: 3)
        let solution = SkyscrapersLogic.generateSolution(using: &generator)
        let clues = SkyscrapersLogic.computeClues(solution)
        XCTAssertGreaterThanOrEqual(SkyscrapersLogic.countSolutions(clues, limit: 2), 1)
    }

    func testLogicSolveNeedsClues() {
        XCTAssertFalse(SkyscrapersLogic.logicSolve(emptyClues()))
    }

    func testPuzzlesFollowTheirModes() {
        for seed in 1...4 {
            var easy = SeededGenerator(seed: UInt64(seed))
            let easyClues = SkyscrapersLogic.makePuzzle(mode: .easy, using: &easy)
            for side in SkyscrapersSide.allCases {
                XCTAssertTrue(easyClues[side].allSatisfy { $0 != 0 }, "Lagano: svi tragovi, seed \(seed)")
            }
            XCTAssertTrue(SkyscrapersLogic.logicSolve(easyClues), "Lagano mora biti rješivo logikom, seed \(seed)")

            var classic = SeededGenerator(seed: UInt64(seed))
            let classicClues = SkyscrapersLogic.makePuzzle(mode: .classic, using: &classic)
            XCTAssertTrue(SkyscrapersLogic.logicSolve(classicClues), "Klasično, seed \(seed)")
            XCTAssertEqual(SkyscrapersLogic.countSolutions(classicClues, limit: 2), 1, "Klasično je jednoznačno, seed \(seed)")
            XCTAssertTrue(SkyscrapersSide.allCases.contains { classicClues[$0].contains(0) }, "Klasično skriva tragove")

            var pro = SeededGenerator(seed: UInt64(seed))
            let proClues = SkyscrapersLogic.makePuzzle(mode: .pro, using: &pro)
            XCTAssertEqual(SkyscrapersLogic.countSolutions(proClues, limit: 2), 1, "Pro je jednoznačno, seed \(seed)")
        }
    }

    // MARK: Provjera ploče

    func testErrorsFlagDuplicatesImmediately() {
        var values = Array(repeating: 0, count: size * size)
        values[0] = 3
        values[3] = 3          // isti red
        values[10] = 3         // isti stupac kao polje 0
        let errors = SkyscrapersLogic.errors(values: values, clues: emptyClues())
        XCTAssertEqual(errors.cells, [0, 3, 10])
    }

    func testClueIsJudgedOnlyOnceLineIsFull() {
        var clues = emptyClues()
        clues.left[0] = 4                                   // pravi trag za [1,2,3,4,5] je 5

        var values = Array(repeating: 0, count: size * size)
        for c in 0..<4 { values[c] = c + 1 }
        XCTAssertTrue(SkyscrapersLogic.errors(values: values, clues: clues).clues.isEmpty)

        values[4] = 5
        XCTAssertEqual(SkyscrapersLogic.errors(values: values, clues: clues).clues,
                       [SkyscrapersClueID(side: .left, index: 0)])
    }

    func testIsSolved() {
        let clues = SkyscrapersLogic.computeClues(cyclic)
        XCTAssertTrue(SkyscrapersLogic.isSolved(values: cyclic, clues: clues))

        var wrong = cyclic
        wrong[0] = 2
        XCTAssertFalse(SkyscrapersLogic.isSolved(values: wrong, clues: clues))

        var incomplete = cyclic
        incomplete[24] = 0
        XCTAssertFalse(SkyscrapersLogic.isSolved(values: incomplete, clues: clues))

        // ispravan latinski kvadrat koji krši trag
        var other = clues
        other.top[0] = 1
        XCTAssertFalse(SkyscrapersLogic.isSolved(values: cyclic, clues: other))
    }

    // MARK: Model

    func testRaiseAndLowerCycleThroughZeroToFive() {
        let model = SkyscrapersModel(clues: SkyscrapersLogic.computeClues(cyclic))
        model.raise(0); XCTAssertEqual(model.values[0], 1)
        model.lower(0); XCTAssertEqual(model.values[0], 0)
        model.lower(0); XCTAssertEqual(model.values[0], 5)
        model.raise(0); XCTAssertEqual(model.values[0], 0)
    }

    func testNothingHappensBeforePuzzleIsLoaded() {
        let model = SkyscrapersModel()
        model.raise(0)
        XCTAssertEqual(model.values[0], 0)
        XCTAssertFalse(model.timer.hasStarted)
    }

    func testSolvingStopsTimerAndLocksBoard() {
        let model = SkyscrapersModel(clues: SkyscrapersLogic.computeClues(cyclic))
        for (i, height) in cyclic.enumerated() {
            for _ in 0..<height { model.raise(i) }
            if i == 0 { XCTAssertTrue(model.timer.isRunning) }
        }
        XCTAssertTrue(model.isSolved)
        XCTAssertFalse(model.timer.isRunning)
        XCTAssertNotNil(model.solveTime)

        model.raise(0)
        XCTAssertEqual(model.values[0], cyclic[0])
    }

    func testClearKeepsCluesAndStartResets() {
        let clues = SkyscrapersLogic.computeClues(cyclic)
        let model = SkyscrapersModel(clues: clues)
        model.raise(0)
        model.clear()
        XCTAssertEqual(model.filledCount, 0)
        XCTAssertEqual(model.clues, clues)

        model.raise(1)
        model.start(clues, mode: .pro)
        XCTAssertEqual(model.mode, .pro)
        XCTAssertEqual(model.filledCount, 0)
        XCTAssertFalse(model.timer.hasStarted)
    }

    func testInactiveGamePausesTimer() {
        let model = SkyscrapersModel(clues: SkyscrapersLogic.computeClues(cyclic))
        model.raise(0)
        XCTAssertTrue(model.timer.isRunning)
        model.setActive(false)
        XCTAssertFalse(model.timer.isRunning)
        model.setActive(true)
        XCTAssertTrue(model.timer.isRunning)
    }
}
