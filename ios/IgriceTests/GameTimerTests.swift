import XCTest
@testable import Igrice

final class GameTimerTests: XCTestCase {
    private var current = Date(timeIntervalSince1970: 1_000)

    private func makeTimer() -> GameTimer {
        GameTimer(now: { [unowned self] in self.current })
    }

    func testRunsFromStartAndPausesAndResumes() {
        let timer = makeTimer()
        timer.start()
        current += 5
        XCTAssertEqual(timer.elapsed(), 5, accuracy: 0.001)

        timer.pause()
        current += 100
        XCTAssertEqual(timer.elapsed(), 5, accuracy: 0.001)

        timer.resume()
        current += 3
        XCTAssertEqual(timer.elapsed(), 8, accuracy: 0.001)
    }

    func testResumeDoesNothingBeforeFirstStart() {
        let timer = makeTimer()
        timer.resume()
        XCTAssertFalse(timer.isRunning)
    }

    func testResetStopsAndZeroes() {
        let timer = makeTimer()
        timer.start()
        current += 4
        timer.reset()
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.elapsed(), 0, accuracy: 0.001)
        timer.resume()
        XCTAssertFalse(timer.isRunning)
    }

    func testRestoreKeepsElapsedAndWaitsForResume() {
        let timer = makeTimer()
        timer.restore(elapsed: 42)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.elapsed(), 42, accuracy: 0.001)

        timer.resume()
        current += 8
        XCTAssertEqual(timer.elapsed(), 50, accuracy: 0.001)
    }

    func testFormat() {
        XCTAssertEqual(GameTimer.format(0), "00:00")
        XCTAssertEqual(GameTimer.format(59.9), "00:59")
        XCTAssertEqual(GameTimer.format(61), "01:01")
        XCTAssertEqual(GameTimer.format(600), "10:00")
    }
}
