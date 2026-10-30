package com.brunodobric.igrice.games.tictactoe

/** Znak igrača: Igrač 1 je X, Igrač 2 je O. */
enum class Mark(val label: String) {
    X("Igrač 1 (X)"),
    O("Igrač 2 (O)");

    val other: Mark get() = if (this == X) O else X
}

/** Ishod partije: pobjeda s dobitnom linijom ili remi. */
sealed interface TicTacToeOutcome {
    data class Win(val winner: Mark, val line: List<Int>) : TicTacToeOutcome
    data object Draw : TicTacToeOutcome
}

/** Ploča 3 × 3. Nepromjenjiva; pravila su prenesena iz index.html (Križić Kružić). */
class TicTacToeBoard(
    val cells: List<Mark?> = List(9) { null },
    val current: Mark = Mark.X,
) {
    /** Isto kao checkWinner() u index.html: najprije linije, pa puna ploča. */
    val outcome: TicTacToeOutcome? by lazy {
        for (line in WINS) {
            val (a, b, c) = line
            val mark = cells[a]
            if (mark != null && mark == cells[b] && mark == cells[c]) return@lazy TicTacToeOutcome.Win(mark, line)
        }
        if (cells.all { it != null }) TicTacToeOutcome.Draw else null
    }

    val isOver: Boolean get() = outcome != null

    /** Igrač na redu stavlja znak; zauzeto polje ili gotova partija ne mijenjaju ništa. */
    fun play(i: Int): TicTacToeBoard {
        if (isOver || cells[i] != null) return this
        val next = cells.toMutableList().also { it[i] = current }
        val board = TicTacToeBoard(next, current)
        return if (board.isOver) board else TicTacToeBoard(next, current.other)
    }

    companion object {
        val WINS = listOf(
            listOf(0, 1, 2), listOf(3, 4, 5), listOf(6, 7, 8),
            listOf(0, 3, 6), listOf(1, 4, 7), listOf(2, 5, 8),
            listOf(0, 4, 8), listOf(2, 4, 6),
        )
    }
}

/** Bodovi u ovoj sesiji (na webu se ne spremaju). */
data class TicTacToeScores(val x: Int = 0, val o: Int = 0, val draws: Int = 0) {
    fun adding(outcome: TicTacToeOutcome): TicTacToeScores = when (outcome) {
        TicTacToeOutcome.Draw -> copy(draws = draws + 1)
        is TicTacToeOutcome.Win -> if (outcome.winner == Mark.X) copy(x = x + 1) else copy(o = o + 1)
    }
}
