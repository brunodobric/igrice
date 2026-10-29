import Foundation
import Observation

/// Mjerač vremena koji se može zaustaviti i nastaviti (isto kao startTimer, pauseTimer,
/// resumeTimer i resetTimer u index.html). Vrijeme se računa iz datuma, ne iz brojača,
/// pa prikaz samo traži `elapsed(at:)`.
@Observable
final class GameTimer {
    private(set) var accrued: TimeInterval = 0
    private(set) var startedAt: Date?
    private(set) var hasStarted = false

    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    var isRunning: Bool { startedAt != nil }

    func elapsed(at date: Date) -> TimeInterval {
        accrued + (startedAt.map { date.timeIntervalSince($0) } ?? 0)
    }

    func elapsed() -> TimeInterval { elapsed(at: now()) }

    /// Prvi potez: pokreće mjerač.
    func start() {
        guard !isRunning else { return }
        hasStarted = true
        startedAt = now()
    }

    func pause() {
        guard let startedAt else { return }
        accrued += now().timeIntervalSince(startedAt)
        self.startedAt = nil
    }

    /// Nastavlja samo ako je igra već počela.
    func resume() {
        guard !isRunning, hasStarted else { return }
        startedAt = now()
    }

    func reset() {
        accrued = 0
        startedAt = nil
        hasStarted = false
    }

    /// Vraća spremljeno vrijeme; mjerač ostaje zaustavljen dok ga igra ne nastavi.
    func restore(elapsed: TimeInterval) {
        accrued = max(0, elapsed)
        startedAt = nil
        hasStarted = elapsed > 0
    }

    /// mm:ss, kao `fmt` u index.html.
    static func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let minutes = total / 60, seconds = total % 60
        return (minutes < 10 ? "0" : "") + "\(minutes):" + (seconds < 10 ? "0" : "") + "\(seconds)"
    }
}
