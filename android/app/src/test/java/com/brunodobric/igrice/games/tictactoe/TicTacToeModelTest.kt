package com.brunodobric.igrice.games.tictactoe

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Test

class TicTacToeModelTest {
    private fun play(vararg moves: Int): TicTacToeBoard =
        moves.fold(TicTacToeBoard()) { board, i -> board.play(i) }

    @Test
    fun playersAlternateStartingWithX() {
        val board = play(4)
        assertEquals(Mark.X, board.cells[4])
        assertEquals(Mark.O, board.current)
        assertEquals(Mark.O, board.play(0).cells[0])
    }

    @Test
    fun takenCellIsIgnored() {
        val board = play(4)
        assertSame(board, board.play(4))
    }

    @Test
    fun rowColumnAndDiagonalWin() {
        assertEquals(TicTacToeOutcome.Win(Mark.X, listOf(0, 1, 2)), play(0, 3, 1, 4, 2).outcome)
        assertEquals(TicTacToeOutcome.Win(Mark.O, listOf(1, 4, 7)), play(0, 1, 2, 4, 3, 7).outcome)
        assertEquals(TicTacToeOutcome.Win(Mark.X, listOf(2, 4, 6)), play(2, 0, 4, 1, 6).outcome)
    }

    @Test
    fun noMovesAfterWin() {
        val won = play(0, 3, 1, 4, 2)
        assertSame(won, won.play(8))
    }

    @Test
    fun fullBoardWithoutLineIsDraw() {
        // X O X / X O O / O X X
        val board = play(0, 1, 2, 4, 3, 5, 7, 6, 8)
        assertEquals(TicTacToeOutcome.Draw, board.outcome)
    }

    @Test
    fun winOnLastMoveBeatsDraw() {
        // X O X / O X O / O X X → X pobjeđuje dijagonalom na zadnjem potezu
        val board = play(0, 1, 2, 3, 4, 5, 7, 6, 8)
        assertEquals(TicTacToeOutcome.Win(Mark.X, listOf(0, 4, 8)), board.outcome)
    }

    @Test
    fun scoresCountOutcomes() {
        val scores = TicTacToeScores()
            .adding(TicTacToeOutcome.Win(Mark.X, listOf(0, 1, 2)))
            .adding(TicTacToeOutcome.Draw)
            .adding(TicTacToeOutcome.Win(Mark.O, listOf(0, 4, 8)))
            .adding(TicTacToeOutcome.Win(Mark.X, listOf(2, 4, 6)))
        assertEquals(TicTacToeScores(x = 2, o = 1, draws = 1), scores)
        assertNull(play().outcome)
    }
}
