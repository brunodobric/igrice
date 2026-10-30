package com.brunodobric.igrice.shared

/**
 * Mjerač vremena koji se može zaustaviti i nastaviti (isto kao startTimer, pauseTimer,
 * resumeTimer i resetTimer u index.html). Vrijeme se računa iz sata, ne iz brojača.
 */
class GameTimer(private val now: () -> Long = { System.nanoTime() / 1_000_000 }) {
    private var accrued = 0L
    private var startedAt: Long? = null

    var hasStarted = false
        private set

    val isRunning: Boolean get() = startedAt != null

    fun elapsedMs(): Long = accrued + (startedAt?.let { now() - it } ?: 0)

    /** Prvi potez: pokreće mjerač. */
    fun start() {
        if (isRunning) return
        hasStarted = true
        startedAt = now()
    }

    fun pause() {
        val started = startedAt ?: return
        accrued += now() - started
        startedAt = null
    }

    /** Nastavlja samo ako je igra već počela. */
    fun resume() {
        if (isRunning || !hasStarted) return
        startedAt = now()
    }

    fun reset() {
        accrued = 0
        startedAt = null
        hasStarted = false
    }

    companion object {
        /** mm:ss kao fmt() u index.html. */
        fun format(ms: Long): String {
            val s = ms / 1000
            return (s / 60).toString().padStart(2, '0') + ":" + (s % 60).toString().padStart(2, '0')
        }
    }
}
