package com.brunodobric.igrice.games.minesweeper

import com.brunodobric.igrice.shared.GameTimer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class MinesweeperModelTest {
    private fun layout(rows: Int, cols: Int, mines: Set<Int>): MinesLayout =
        MinesLayout(mines, MinesweeperLogic.adjacency(mines, MinesGeometry(rows, cols)), mayNeedGuess = false)

    @Test
    fun neighboursOfCornerEdgeAndCentre() {
        val g = MinesGeometry(8, 8)
        assertEquals(setOf(1, 8, 9), g.neighbours[0].toSet())
        assertEquals(5, g.neighbours[3].size)
        assertEquals(8, g.neighbours[9].size)
    }

    @Test
    fun firstMoveAndNeighboursAreAlwaysSafe() {
        for (level in MinesweeperLevel.entries) {
            val safe = level.rows * level.cols / 2 + 1
            val layout = MinesweeperLogic.makeLayout(level.rows, level.cols, level.mines, safe, 2000, Random(7))
            val geometry = MinesGeometry(level.rows, level.cols)
            assertEquals(level.mines, layout.mines.size)
            assertFalse(safe in layout.mines)
            assertTrue(geometry.neighbours[safe].none { it in layout.mines })
        }
    }

    @Test
    fun generatedBoardsAreSolvableWithoutGuessing() {
        val random = Random(42)
        for (level in MinesweeperLevel.entries) {
            repeat(5) {
                val safe = random.nextInt(level.rows * level.cols)
                val layout = MinesweeperLogic.makeLayout(level.rows, level.cols, level.mines, safe, 2000, random)
                assertFalse("${level.label}: ploča bez pogađanja nije nađena", layout.mayNeedGuess)
                assertTrue(
                    MinesweeperLogic.isNoGuess(layout.mines, layout.adjacency, safe, MinesGeometry(level.rows, level.cols)),
                )
            }
        }
    }

    @Test
    fun noGuessCheckRecognisesLogicAndFiftyFifty() {
        // 1 × 3, mina desno: otvori se lijevo, broj 1 ima samo jedno nepoznato polje → rješivo
        val line = MinesGeometry(1, 3)
        val one = setOf(2)
        assertTrue(MinesweeperLogic.isNoGuess(one, MinesweeperLogic.adjacency(one, line), 0, line))
        // 2 × 3, mina gore desno: oba broja 1 vide ista dva polja u desnom stupcu → klasični 50/50
        val grid = MinesGeometry(2, 3)
        assertFalse(MinesweeperLogic.isNoGuess(one, MinesweeperLogic.adjacency(one, grid), 0, grid))
    }

    @Test
    fun revealFloodsZerosAndWins() {
        val level = MinesweeperLevel.EASY
        val mines = setOf(63)
        var board = MinesweeperBoard(level).reveal(0, layout(8, 8, mines))
        assertFalse(board.isFirstMove)
        assertEquals(63, board.revealedCount)
        assertEquals(MinesweeperOutcome.Won, board.outcome)
        assertTrue(board.cells[63].isFlagged)
        assertEquals(0, board.minesLeft)
        // potez nakon kraja ne mijenja ništa
        assertEquals(board, board.reveal(63))
        board = board.toggleFlag(10)
        assertEquals(MinesweeperOutcome.Won, board.outcome)
    }

    @Test
    fun hittingAMineLosesAndShowsWrongFlags() {
        val mines = setOf(9, 63) // 9 je dijagonalno do kuta, pa se otvara samo kut s brojem 1
        var board = MinesweeperBoard(MinesweeperLevel.EASY).reveal(0, layout(8, 8, mines))
        assertNull(board.outcome)
        assertEquals(1, board.revealedCount)
        assertEquals(1, board.cells[0].adjacent)
        val wrong = 1
        board = board.toggleFlag(wrong)
        assertEquals(1, board.flags)
        board = board.reveal(9)
        assertEquals(MinesweeperOutcome.Lost(9), board.outcome)
        assertTrue(mines.all { board.cells[it].isRevealed })
        assertTrue(board.isWrongFlag(wrong))
    }

    @Test
    fun flaggedCellCannotBeRevealedAndFlagToggles() {
        var board = MinesweeperBoard(MinesweeperLevel.EASY)
        board = board.toggleFlag(5)
        assertEquals(9, board.minesLeft)
        assertEquals(board, board.reveal(5, layout(8, 8, setOf(63))))
        board = board.toggleFlag(5)
        assertEquals(0, board.flags)
    }

    @Test
    fun timerPausesAndFormats() {
        var now = 0L
        val timer = GameTimer { now }
        timer.resume()
        assertFalse(timer.isRunning)
        timer.start()
        now = 61_500
        timer.pause()
        now = 100_000
        assertEquals(61_500, timer.elapsedMs())
        timer.resume()
        now = 101_000
        assertEquals("01:02", GameTimer.format(timer.elapsedMs()))
        timer.reset()
        assertEquals(0, timer.elapsedMs())
    }
}
