package com.brunodobric.igrice.games.minesweeper

import kotlin.random.Random

/** Razine kao LEVELS u index.html. Ključ se koristi i za spremanje rekorda (`mines-best-<ključ>`). */
enum class MinesweeperLevel(val key: String, val size: Int, val mines: Int, val label: String) {
    EASY("easy", 8, 10, "Lako"),
    MEDIUM("medium", 12, 30, "Srednje"),
    HARD("hard", 16, 50, "Teško");

    val rows: Int get() = size
    val cols: Int get() = size

    companion object {
        fun fromKey(key: String?): MinesweeperLevel = entries.firstOrNull { it.key == key } ?: EASY
    }
}

/** Raspored mina i brojeva uz mine, nastao nakon prvog dodira. */
class MinesLayout(
    val mines: Set<Int>,
    /** Broj susjednih mina; kod mina je -1 i ne čita se. */
    val adjacency: IntArray,
    /** true samo ako ploča bez pogađanja nije nađena u zadanom roku. */
    val mayNeedGuess: Boolean,
)

/** Susjedi svakog polja, izračunati jednom. */
class MinesGeometry(val rows: Int, val cols: Int) {
    val neighbours: List<IntArray> = List(rows * cols) { i ->
        val r = i / cols
        val c = i % cols
        buildList {
            for (dr in -1..1) for (dc in -1..1) {
                if (dr == 0 && dc == 0) continue
                val nr = r + dr
                val nc = c + dc
                if (nr in 0 until rows && nc in 0 until cols) add(nr * cols + nc)
            }
        }.toIntArray()
    }
}

/** Generator ploče bez pogađanja i provjera rješivosti. Algoritam je prenesen iz index.html. */
object MinesweeperLogic {
    private const val UNKNOWN = 0
    private const val SAFE = 1
    private const val MINE = 2

    fun adjacency(mines: Set<Int>, geometry: MinesGeometry): IntArray =
        IntArray(geometry.rows * geometry.cols) { i ->
            if (i in mines) -1 else geometry.neighbours[i].count { it in mines }
        }

    /**
     * Može li se raspored riješiti od `start` samo logikom? Simulira rješavača: otvaranje praznina,
     * pa redom pravilo jednog polja, pravilo podskupa (1-2) i pravilo ukupnog broja mina.
     */
    fun isNoGuess(mines: Set<Int>, adjacency: IntArray, start: Int, geometry: MinesGeometry): Boolean {
        val total = geometry.rows * geometry.cols
        val state = IntArray(total) // UNKNOWN, SAFE ili MINE

        fun revealFlood(first: Int) {
            val stack = ArrayDeque<Int>().apply { addLast(first) }
            while (stack.isNotEmpty()) {
                val c = stack.removeLast()
                if (state[c] != UNKNOWN || c in mines) continue
                state[c] = SAFE
                if (adjacency[c] == 0) {
                    for (n in geometry.neighbours[c]) if (state[n] == UNKNOWN) stack.addLast(n)
                }
            }
        }

        fun openCell(u: Int) {
            if (adjacency[u] == 0) revealFlood(u) else state[u] = SAFE
        }

        revealFlood(start)

        var changed = true
        while (changed) {
            changed = false

            // jedno polje: broj s pronađenim svim minama, ostalo je sigurno; sve nepoznato su mine
            for (i in 0 until total) {
                if (state[i] != SAFE || adjacency[i] == 0) continue
                val nb = geometry.neighbours[i]
                val unknown = nb.filter { state[it] == UNKNOWN }
                if (unknown.isEmpty()) continue
                val remaining = adjacency[i] - nb.count { state[it] == MINE }
                if (remaining == 0) {
                    for (u in unknown) {
                        if (state[u] != UNKNOWN) continue
                        changed = true
                        openCell(u)
                    }
                } else if (remaining == unknown.size) {
                    for (u in unknown) {
                        state[u] = MINE
                        changed = true
                    }
                }
            }
            if (changed) continue

            // podskup (1-2): ako su nepoznata polja A podskup polja B, razlika ima B.mine - A.mine mina
            val constraints = mutableListOf<Pair<Set<Int>, Int>>()
            for (i in 0 until total) {
                if (state[i] != SAFE || adjacency[i] == 0) continue
                val nb = geometry.neighbours[i]
                val unknown = nb.filter { state[it] == UNKNOWN }
                if (unknown.isEmpty()) continue
                constraints += unknown.toSet() to adjacency[i] - nb.count { state[it] == MINE }
            }
            for ((ai, a) in constraints.withIndex()) {
                for ((bi, b) in constraints.withIndex()) {
                    val (aCells, aMines) = a
                    val (bCells, bMines) = b
                    if (ai == bi || aCells.size >= bCells.size || !bCells.containsAll(aCells)) continue
                    val difference = bCells - aCells
                    val differenceMines = bMines - aMines
                    if (differenceMines == 0) {
                        for (u in difference) {
                            if (state[u] != UNKNOWN) continue
                            changed = true
                            openCell(u)
                        }
                    } else if (differenceMines == difference.size) {
                        for (u in difference) {
                            if (state[u] == UNKNOWN) {
                                state[u] = MINE
                                changed = true
                            }
                        }
                    }
                }
                if (changed) break
            }
            if (changed) continue

            // ukupan broj: preostale mine prema preostalim nepoznatim poljima
            val unknownCells = (0 until total).filter { state[it] == UNKNOWN }
            val knownMines = state.count { it == MINE }
            val remainingMines = mines.size - knownMines
            if (unknownCells.isNotEmpty()) {
                if (remainingMines == 0) {
                    for (u in unknownCells) {
                        if (state[u] != UNKNOWN) continue
                        changed = true
                        openCell(u)
                    }
                } else if (remainingMines == unknownCells.size) {
                    for (u in unknownCells) {
                        state[u] = MINE
                        changed = true
                    }
                }
            }
        }

        return (0 until total).all { it in mines || state[it] == SAFE }
    }

    fun makeLayout(level: MinesweeperLevel, safe: Int, timeBudgetMs: Long = 2000): MinesLayout =
        makeLayout(level.rows, level.cols, level.mines, safe, timeBudgetMs, Random.Default)

    /**
     * Mine se postavljaju nakon prvog dodira, tako da je on (i njegovi susjedi) siguran i, ako ide,
     * da se cijela ploča može riješiti logikom. Ako se u roku `timeBudgetMs` ne nađe takva, uzima se bilo koja.
     */
    fun makeLayout(
        rows: Int,
        cols: Int,
        mineCount: Int,
        safe: Int,
        timeBudgetMs: Long,
        random: Random,
    ): MinesLayout {
        val geometry = MinesGeometry(rows, cols)
        val safeSet = geometry.neighbours[safe].toSet() + safe
        val pool = (0 until rows * cols).filter { it !in safeSet }
        val count = minOf(mineCount, pool.size)

        fun sample(): Set<Int> {
            val p = pool.toIntArray()
            for (k in 0 until count) {
                val j = k + random.nextInt(p.size - k)
                p[k] = p[j].also { p[j] = p[k] }
            }
            return p.take(count).toSet()
        }

        val deadline = System.currentTimeMillis() + timeBudgetMs
        while (System.currentTimeMillis() < deadline) {
            val candidate = sample()
            val counts = adjacency(candidate, geometry)
            if (isNoGuess(candidate, counts, safe, geometry)) {
                return MinesLayout(candidate, counts, mayNeedGuess = false)
            }
        }
        val fallback = sample()
        return MinesLayout(fallback, adjacency(fallback, geometry), mayNeedGuess = true)
    }
}

/** Jedno polje ploče. */
data class MineCell(
    val isMine: Boolean = false,
    val adjacent: Int = 0,
    val isRevealed: Boolean = false,
    val isFlagged: Boolean = false,
)

sealed interface MinesweeperOutcome {
    data object Won : MinesweeperOutcome
    data class Lost(val exploded: Int) : MinesweeperOutcome
}

/**
 * Stanje jedne partije Minolovca. Nepromjenjivo: svaki potez vraća novo stanje,
 * pa ga prikaz može samo držati u `State` i ponovno nacrtati.
 */
data class MinesweeperBoard(
    val level: MinesweeperLevel,
    val cells: List<MineCell> = List(level.rows * level.cols) { MineCell() },
    val mineCount: Int = level.mines,
    val flags: Int = 0,
    val revealedCount: Int = 0,
    val isFirstMove: Boolean = true,
    val mayNeedGuess: Boolean = false,
    val outcome: MinesweeperOutcome? = null,
) {
    val rows: Int get() = level.rows
    val cols: Int get() = level.cols
    val minesLeft: Int get() = mineCount - flags
    val isOver: Boolean get() = outcome != null

    /** Pogrešno postavljena zastavica prikazuje se tek kad je igra izgubljena. */
    fun isWrongFlag(i: Int): Boolean =
        outcome is MinesweeperOutcome.Lost && cells[i].isFlagged && !cells[i].isMine

    /**
     * Otkriva polje. Na prvi dodir se postavljaju mine; `layout` se može dati unaprijed
     * (prikaz ga izračuna u pozadini), inače se računa ovdje.
     */
    fun reveal(i: Int, layout: MinesLayout? = null): MinesweeperBoard {
        if (isOver || i !in cells.indices || cells[i].isFlagged || cells[i].isRevealed) return this

        var board = this
        if (isFirstMove) board = board.apply(layout ?: MinesweeperLogic.makeLayout(level, i))

        if (board.cells[i].isMine) return board.lose(i)
        return board.flood(i).checkWin()
    }

    /** Postavlja ili skida zastavicu. */
    fun toggleFlag(i: Int): MinesweeperBoard {
        if (isOver || i !in cells.indices || cells[i].isRevealed) return this
        val flagged = !cells[i].isFlagged
        return copy(
            cells = cells.toMutableList().also { it[i] = it[i].copy(isFlagged = flagged) },
            flags = flags + if (flagged) 1 else -1,
        )
    }

    private fun apply(layout: MinesLayout) = copy(
        cells = cells.mapIndexed { i, cell ->
            cell.copy(isMine = i in layout.mines, adjacent = maxOf(0, layout.adjacency[i]))
        },
        mineCount = layout.mines.size,
        mayNeedGuess = layout.mayNeedGuess,
        isFirstMove = false,
    )

    private fun flood(start: Int): MinesweeperBoard {
        val geometry = MinesGeometry(rows, cols)
        val next = cells.toMutableList()
        var revealed = revealedCount
        val stack = ArrayDeque<Int>().apply { addLast(start) }
        while (stack.isNotEmpty()) {
            val i = stack.removeLast()
            val cell = next[i]
            if (cell.isRevealed || cell.isFlagged) continue
            next[i] = cell.copy(isRevealed = true)
            revealed++
            if (cell.adjacent == 0) {
                for (n in geometry.neighbours[i]) if (!next[n].isRevealed) stack.addLast(n)
            }
        }
        return copy(cells = next, revealedCount = revealed)
    }

    private fun lose(hit: Int) = copy(
        cells = cells.map { if (it.isMine && !it.isFlagged) it.copy(isRevealed = true) else it },
        outcome = MinesweeperOutcome.Lost(hit),
    )

    private fun checkWin(): MinesweeperBoard {
        if (revealedCount != rows * cols - mineCount) return this
        // preostale mine dobiju zastavicu za uredan kraj
        return copy(
            cells = cells.map { if (it.isMine) it.copy(isFlagged = true) else it },
            flags = mineCount,
            outcome = MinesweeperOutcome.Won,
        )
    }
}
