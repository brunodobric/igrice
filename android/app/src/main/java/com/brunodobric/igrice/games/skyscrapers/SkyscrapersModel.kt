package com.brunodobric.igrice.games.skyscrapers

import kotlin.random.Random

/** Ploča je 5 × 5, visine od 1 do 5. */
const val SKY_SIZE = 5

/**
 * Razine kao `#sky-levels` u index.html. Ključ se koristi i za spremanje rekorda (`sky-best-<ključ>`).
 * Lagano prikazuje sve tragove, Klasično je rješivo logikom, a Pro ima jedno rješenje
 * koje može tražiti pogađanje.
 */
enum class SkyscrapersLevel(val key: String, val label: String, val hint: String) {
    EASY("easy", "Lagano", "Prikazani su svi tragovi"),
    CLASSIC("classic", "Klasično", "Rješivo logikom, bez pogađanja"),
    PRO("pro", "Pro", "Jedno rješenje, ali može tražiti pogađanje");

    companion object {
        fun fromKey(key: String?): SkyscrapersLevel = entries.firstOrNull { it.key == key } ?: CLASSIC
    }
}

/** Strana ploče s koje se gleda. */
enum class Side { TOP, BOTTOM, LEFT, RIGHT }

/** Tragovi uz rub; 0 znači skriven trag. Svaki niz ima [SKY_SIZE] elemenata. */
class Clues(val top: IntArray, val bottom: IntArray, val left: IntArray, val right: IntArray) {
    operator fun get(side: Side): IntArray = when (side) {
        Side.TOP -> top
        Side.BOTTOM -> bottom
        Side.LEFT -> left
        Side.RIGHT -> right
    }

    fun copy() = Clues(top.copyOf(), bottom.copyOf(), left.copyOf(), right.copyOf())

    val shown: Int get() = Side.entries.sumOf { side -> this[side].count { it != 0 } }
}

/** Generator i rješavači. Algoritmi su preneseni iz index.html (Neboderi). */
object SkyscrapersLogic {
    private fun idx(r: Int, c: Int) = r * SKY_SIZE + c

    /** Sve permutacije 1..5, za rješavač po linijama. */
    private val perms: List<IntArray> = buildList {
        fun perm(acc: List<Int>, rest: List<Int>) {
            if (rest.isEmpty()) {
                add(acc.toIntArray())
                return
            }
            for (k in rest.indices) perm(acc + rest[k], rest.filterIndexed { j, _ -> j != k })
        }
        perm(emptyList(), (1..SKY_SIZE).toList())
    }

    /** Koliko se nebodera vidi gledajući duž niza visina. */
    fun visible(line: IntArray): Int {
        var max = 0
        var count = 0
        for (v in line) if (v > max) {
            max = v
            count++
        }
        return count
    }

    fun row(b: IntArray, r: Int) = IntArray(SKY_SIZE) { b[idx(r, it)] }

    fun column(b: IntArray, c: Int) = IntArray(SKY_SIZE) { b[idx(it, c)] }

    /** Nasumični latinski kvadrat: svaki red i stupac je permutacija 1..5. */
    fun generateSolution(random: Random = Random.Default): IntArray {
        val b = IntArray(SKY_SIZE * SKY_SIZE)
        val rowUsed = Array(SKY_SIZE) { BooleanArray(SKY_SIZE + 1) }
        val columnUsed = Array(SKY_SIZE) { BooleanArray(SKY_SIZE + 1) }

        fun fill(pos: Int): Boolean {
            if (pos == b.size) return true
            val r = pos / SKY_SIZE
            val c = pos % SKY_SIZE
            for (v in (1..SKY_SIZE).shuffled(random)) {
                if (rowUsed[r][v] || columnUsed[c][v]) continue
                b[pos] = v
                rowUsed[r][v] = true
                columnUsed[c][v] = true
                if (fill(pos + 1)) return true
                b[pos] = 0
                rowUsed[r][v] = false
                columnUsed[c][v] = false
            }
            return false
        }

        fill(0)
        return b
    }

    /** Tragovi sa svih strana potpunog rješenja. */
    fun computeClues(solution: IntArray): Clues {
        val clues = Clues(IntArray(SKY_SIZE), IntArray(SKY_SIZE), IntArray(SKY_SIZE), IntArray(SKY_SIZE))
        for (i in 0 until SKY_SIZE) {
            val column = column(solution, i)
            val row = row(solution, i)
            clues.top[i] = visible(column)
            clues.bottom[i] = visible(column.reversedArray())
            clues.left[i] = visible(row)
            clues.right[i] = visible(row.reversedArray())
        }
        return clues
    }

    /** Broji rješenja u skladu s tragovima, najviše do `limit`. */
    fun countSolutions(clues: Clues, limit: Int): Int {
        val g = IntArray(SKY_SIZE * SKY_SIZE)
        val rowUsed = Array(SKY_SIZE) { BooleanArray(SKY_SIZE + 1) }
        val columnUsed = Array(SKY_SIZE) { BooleanArray(SKY_SIZE + 1) }
        var count = 0

        fun fill(pos: Int) {
            if (count >= limit) return
            if (pos == g.size) {
                count++
                return
            }
            val r = pos / SKY_SIZE
            val c = pos % SKY_SIZE
            for (v in 1..SKY_SIZE) {
                if (rowUsed[r][v] || columnUsed[c][v]) continue
                g[pos] = v
                rowUsed[r][v] = true
                columnUsed[c][v] = true
                var good = true
                if (c == SKY_SIZE - 1) {   // red r je pun
                    val row = row(g, r)
                    if (clues.left[r] != 0 && visible(row) != clues.left[r]) good = false
                    if (good && clues.right[r] != 0 && visible(row.reversedArray()) != clues.right[r]) good = false
                }
                if (good && r == SKY_SIZE - 1) {   // stupac c je pun
                    val column = column(g, c)
                    if (clues.top[c] != 0 && visible(column) != clues.top[c]) good = false
                    if (good && clues.bottom[c] != 0 && visible(column.reversedArray()) != clues.bottom[c]) good = false
                }
                if (good) fill(pos + 1)
                g[pos] = 0
                rowUsed[r][v] = false
                columnUsed[c][v] = false
                if (count >= limit) return
            }
        }

        fill(0)
        return count
    }

    /**
     * Rješava samo logikom po linijama: u svakom redu i stupcu ostaju visine koje podržava
     * barem jedan raspored u skladu s kandidatima i tragovima te linije. Nikad ne pogađa.
     * Vraća rješenje samo ako tako odredi cijelu ploču; inače null.
     */
    fun logicSolve(clues: Clues): IntArray? {
        val all = (1 shl (SKY_SIZE + 1)) - 2   // bitovi 1..5
        val candidates = IntArray(SKY_SIZE * SKY_SIZE) { all }
        var changed = true
        while (changed) {
            changed = false
            for (isRow in booleanArrayOf(true, false)) {
                for (i in 0 until SKY_SIZE) {
                    val cells = IntArray(SKY_SIZE) { k -> if (isRow) idx(i, k) else idx(k, i) }
                    val front = if (isRow) clues.left[i] else clues.top[i]
                    val back = if (isRow) clues.right[i] else clues.bottom[i]
                    val allowed = IntArray(SKY_SIZE)
                    var any = false
                    for (perm in perms) {
                        if ((0 until SKY_SIZE).any { k -> candidates[cells[k]] and (1 shl perm[k]) == 0 }) continue
                        if (front != 0 && visible(perm) != front) continue
                        if (back != 0 && visible(perm.reversedArray()) != back) continue
                        any = true
                        for (k in 0 until SKY_SIZE) allowed[k] = allowed[k] or (1 shl perm[k])
                    }
                    if (!any) return null   // nema valjanog rasporeda: proturječje
                    for (k in 0 until SKY_SIZE) {
                        val narrowed = candidates[cells[k]] and allowed[k]
                        if (narrowed != candidates[cells[k]]) {
                            candidates[cells[k]] = narrowed
                            changed = true
                        }
                        if (narrowed == 0) return null
                    }
                }
            }
        }
        if (candidates.any { Integer.bitCount(it) != 1 }) return null
        return IntArray(candidates.size) { Integer.numberOfTrailingZeros(candidates[it]) }
    }

    /**
     * Nova zagonetka s što manje tragova. Lagano zadržava sve tragove (i dalje rješivo logikom),
     * Klasično mora ostati rješivo logikom, a Pro mora imati jedinstveno rješenje.
     */
    fun makePuzzle(level: SkyscrapersLevel, random: Random = Random.Default): Clues {
        fun candidates() = generateSequence { computeClues(generateSolution(random)) }.take(400)
        if (level == SkyscrapersLevel.EASY) {
            // svi tragovi prikazani: najlakša ploča, i dalje bez pogađanja
            return candidates().firstOrNull { logicSolve(it) != null } ?: computeClues(generateSolution(random))
        }
        val solvable: (Clues) -> Boolean = if (level == SkyscrapersLevel.CLASSIC) {
            { logicSolve(it) != null }
        } else {
            { countSolutions(it, 2) == 1 }
        }

        val full = candidates().firstOrNull(solvable) ?: computeClues(generateSolution(random))   // krajnja nužda
        val clues = full.copy()

        val positions = Side.entries.flatMap { side -> (0 until SKY_SIZE).map { side to it } }
        for ((side, i) in positions.shuffled(random)) {
            val saved = clues[side][i]
            clues[side][i] = 0
            if (!solvable(clues)) clues[side][i] = saved   // trag je potreban, vrati ga
        }
        return clues
    }
}

/** Stanje partije: tragovi i upisane visine (0 je prazno). Nepromjenjivo. */
class SkyscrapersBoard(
    val level: SkyscrapersLevel,
    val clues: Clues,
    val values: IntArray = IntArray(SKY_SIZE * SKY_SIZE),
) {
    val filled: Int get() = values.count { it != 0 }

    /** Dodir povećava visinu (prazno → 1 → … → 5 → prazno), dugi pritisak je smanjuje. */
    fun step(i: Int, direction: Int): SkyscrapersBoard =
        SkyscrapersBoard(level, clues, values.copyOf().also {
            it[i] = (it[i] + direction + SKY_SIZE + 1) % (SKY_SIZE + 1)
        })

    fun cleared(): SkyscrapersBoard = SkyscrapersBoard(level, clues)

    /** Polja s istom visinom dvaput u redu ili stupcu. */
    val badCells: Set<Int> by lazy {
        buildSet {
            for (k in 0 until SKY_SIZE) {
                for (line in listOf(List(SKY_SIZE) { k * SKY_SIZE + it }, List(SKY_SIZE) { it * SKY_SIZE + k })) {
                    line.filter { values[it] != 0 }
                        .groupBy { values[it] }
                        .values
                        .filter { it.size > 1 }
                        .forEach { addAll(it) }
                }
            }
        }
    }

    /** Prekršeni tragovi; linija se ocjenjuje tek kad je cijela popunjena. */
    val badClues: Set<Pair<Side, Int>> by lazy {
        buildSet {
            for (i in 0 until SKY_SIZE) {
                val row = SkyscrapersLogic.row(values, i)
                val column = SkyscrapersLogic.column(values, i)
                for ((side, line) in listOf(
                    Side.LEFT to row, Side.RIGHT to row.reversedArray(),
                    Side.TOP to column, Side.BOTTOM to column.reversedArray(),
                )) {
                    val clue = clues[side][i]
                    if (clue != 0 && line.all { it != 0 } && SkyscrapersLogic.visible(line) != clue) add(side to i)
                }
            }
        }
    }

    val hasErrors: Boolean get() = badCells.isNotEmpty() || badClues.isNotEmpty()

    /** Puna ploča bez ponavljanja i u skladu sa svim tragovima (isSolved u index.html). */
    val isSolved: Boolean get() = values.none { it == 0 } && !hasErrors
}
