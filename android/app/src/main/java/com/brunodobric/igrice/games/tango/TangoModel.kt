package com.brunodobric.igrice.games.tango

import kotlin.random.Random

/** Ploča je 6 × 6, a u svakom redu i stupcu mora biti po 3 X i 3 O. */
const val TANGO_SIZE = 6
private const val NEED = 3

/** Vrijednost polja: 0 je prazno, kao u index.html. */
const val EMPTY = 0
const val SUN = 1   // X
const val MOON = 2  // O

private fun idx(r: Int, c: Int) = r * TANGO_SIZE + c

/** Znak između dva susjedna polja: = (ista) ili × (različita). Uvijek vrijedi a < b. */
data class TangoConstraint(val a: Int, val b: Int, val isEqual: Boolean) {
    /** Je li par vrijednosti prekršaj? Prazna polja nikad nisu prekršaj. */
    fun isViolated(va: Int, vb: Int): Boolean =
        va != EMPTY && vb != EMPTY && (if (isEqual) va != vb else va == vb)

    /** Vodoravan znak stoji između stupaca, okomit između redaka. */
    val isHorizontal: Boolean get() = b == a + 1
}

/** Zadana polja i znakovi; zagonetka ima jedinstveno rješenje do kojeg se dolazi logikom. */
class TangoPuzzle(val given: IntArray, val constraints: List<TangoConstraint>) {
    private val byEdge: Map<Long, TangoConstraint> = constraints.associateBy { edge(it.a, it.b) }

    fun constraint(i: Int, j: Int): TangoConstraint? = byEdge[edge(i, j)]

    private fun edge(i: Int, j: Int): Long = minOf(i, j).toLong() * 100 + maxOf(i, j)
}

/** Generator i rješavač. Algoritmi su preneseni iz index.html (Tango). */
object TangoLogic {
    /** Broj znakova = / × u zagonetki (numCons u index.html). */
    const val CONSTRAINT_COUNT = 7

    /**
     * Bi li `v` na polju `i` odmah prekršio pravilo na trenutačnoj (djelomičnoj) ploči?
     * Broje se samo sigurni prekršaji: zato je potez koji iz toga slijedi prisilan.
     */
    fun forbidden(b: IntArray, i: Int, v: Int, puzzle: TangoPuzzle): Boolean {
        val r = i / TANGO_SIZE
        val c = i % TANGO_SIZE
        fun value(rr: Int, cc: Int) =
            if (rr !in 0 until TANGO_SIZE || cc !in 0 until TANGO_SIZE) -1 else b[idx(rr, cc)]

        // red ili stupac već ima 3 ista znaka
        var inRow = 0
        var inColumn = 0
        for (k in 0 until TANGO_SIZE) {
            if (b[idx(r, k)] == v) inRow++
            if (b[idx(k, c)] == v) inColumn++
        }
        if (inRow >= NEED || inColumn >= NEED) return true

        // tri ista u nizu (polje kao kraj, sredina ili početak trojke)
        if (value(r, c - 1) == v && value(r, c - 2) == v) return true
        if (value(r, c - 1) == v && value(r, c + 1) == v) return true
        if (value(r, c + 1) == v && value(r, c + 2) == v) return true
        if (value(r - 1, c) == v && value(r - 2, c) == v) return true
        if (value(r - 1, c) == v && value(r + 1, c) == v) return true
        if (value(r + 1, c) == v && value(r + 2, c) == v) return true

        // znakovi = i × prema već popunjenim susjedima
        for ((nr, nc) in listOf(r to c - 1, r to c + 1, r - 1 to c, r + 1 to c)) {
            if (nr !in 0 until TANGO_SIZE || nc !in 0 until TANGO_SIZE) continue
            val j = idx(nr, nc)
            val constraint = puzzle.constraint(i, j) ?: continue
            if (constraint.isViolated(v, b[j])) return true
        }
        return false
    }

    /**
     * Rješava samo prisilnim potezima (polje na kojem je jedan od dva znaka nemoguć).
     * Vraća rješenje samo ako se tako popuni cijela ploča, tj. bez pogađanja; inače null.
     */
    fun logicSolve(puzzle: TangoPuzzle, givens: IntArray = puzzle.given): IntArray? {
        val b = givens.copyOf()
        var changed = true
        while (changed) {
            changed = false
            for (i in b.indices) {
                if (b[i] != EMPTY) continue
                val canSun = !forbidden(b, i, SUN, puzzle)
                val canMoon = !forbidden(b, i, MOON, puzzle)
                if (!canSun && !canMoon) return null   // proturječje
                if (canSun != canMoon) {
                    b[i] = if (canSun) SUN else MOON
                    changed = true
                }
            }
        }
        return if (b.all { it != EMPTY }) b else null
    }

    /** Jedna nasumična, potpuno riješena ploča (povratno pretraživanje). */
    fun generateSolution(random: Random = Random.Default): IntArray {
        val b = IntArray(TANGO_SIZE * TANGO_SIZE)
        val rowCount = Array(TANGO_SIZE) { IntArray(3) }
        val columnCount = Array(TANGO_SIZE) { IntArray(3) }

        fun ok(r: Int, c: Int, v: Int): Boolean {
            if (rowCount[r][v] >= NEED || columnCount[c][v] >= NEED) return false
            if (c >= 2 && b[idx(r, c - 1)] == v && b[idx(r, c - 2)] == v) return false
            if (r >= 2 && b[idx(r - 1, c)] == v && b[idx(r - 2, c)] == v) return false
            return true
        }

        fun fill(pos: Int): Boolean {
            if (pos == b.size) return true
            val r = pos / TANGO_SIZE
            val c = pos % TANGO_SIZE
            val options = if (random.nextBoolean()) intArrayOf(SUN, MOON) else intArrayOf(MOON, SUN)
            for (v in options) {
                if (!ok(r, c, v)) continue
                b[pos] = v
                rowCount[r][v]++
                columnCount[c][v]++
                if (fill(pos + 1)) return true
                b[pos] = EMPTY
                rowCount[r][v]--
                columnCount[c][v]--
            }
            return false
        }

        fill(0)
        return b
    }

    /**
     * Nova zagonetka: iz rješenja se uzme 7 nasumičnih znakova, a zatim se polja skrivaju
     * redom dok god je zagonetka rješiva samim logičkim potezima (dakle jedinstvena i bez pogađanja).
     */
    fun makePuzzle(random: Random = Random.Default): TangoPuzzle {
        val solution = generateSolution(random)

        val edges = buildList {
            for (r in 0 until TANGO_SIZE) for (c in 0 until TANGO_SIZE) {
                if (c < TANGO_SIZE - 1) add(idx(r, c) to idx(r, c + 1))
                if (r < TANGO_SIZE - 1) add(idx(r, c) to idx(r + 1, c))
            }
        }.shuffled(random)
        val constraints = edges.take(CONSTRAINT_COUNT).map { (a, b) ->
            TangoConstraint(a, b, isEqual = solution[a] == solution[b])
        }

        val givens = solution.copyOf()
        val withConstraints = TangoPuzzle(givens, constraints)
        for (i in givens.indices.shuffled(random)) {
            val saved = givens[i]
            givens[i] = EMPTY
            if (logicSolve(withConstraints, givens) == null) givens[i] = saved
        }
        return TangoPuzzle(givens.copyOf(), constraints)
    }
}

/** Stanje partije: zagonetka i trenutačno upisane vrijednosti. Nepromjenjivo. */
class TangoBoard(val puzzle: TangoPuzzle, val values: IntArray = puzzle.given.copyOf()) {

    fun isGiven(i: Int): Boolean = puzzle.given[i] != EMPTY

    val filled: Int get() = values.count { it != EMPTY }

    /** Dodir: prazno → X → O → prazno. */
    fun cycle(i: Int): TangoBoard = set(i, (values[i] + 1) % 3)

    /** Dugi pritisak: O ↔ prazno. */
    fun toggleMoon(i: Int): TangoBoard = set(i, if (values[i] == MOON) EMPTY else MOON)

    /** Briše sve osim zadanih polja. */
    fun cleared(): TangoBoard = TangoBoard(puzzle)

    private fun set(i: Int, v: Int): TangoBoard {
        if (isGiven(i)) return this
        return TangoBoard(puzzle, values.copyOf().also { it[i] = v })
    }

    /** Pogrešna polja i znakovi (computeErrors u index.html). */
    val errors: TangoErrors by lazy { computeErrors() }

    private fun computeErrors(): TangoErrors {
        val bad = mutableSetOf<Int>()
        val lines = buildList {
            for (k in 0 until TANGO_SIZE) {
                add(List(TANGO_SIZE) { idx(k, it) })   // red
                add(List(TANGO_SIZE) { idx(it, k) })   // stupac
            }
        }
        for (line in lines) {
            // previše istih znakova u redu ili stupcu
            for (v in intArrayOf(SUN, MOON)) {
                if (line.count { values[it] == v } > NEED) bad += line.filter { values[it] == v }
            }
            // tri ista u nizu
            for (k in 0..TANGO_SIZE - 3) {
                val a = values[line[k]]
                if (a != EMPTY && a == values[line[k + 1]] && a == values[line[k + 2]]) {
                    bad += line.subList(k, k + 3)
                }
            }
        }
        // prekršeni znakovi (samo kad su oba polja popunjena)
        val badConstraints = puzzle.constraints.filter { it.isViolated(values[it.a], values[it.b]) }.toSet()
        for (constraint in badConstraints) {
            bad += constraint.a
            bad += constraint.b
        }
        return TangoErrors(bad, badConstraints)
    }

    /** Ploča je puna i bez ijedne greške (isSolved u index.html). */
    val isSolved: Boolean get() = values.none { it == EMPTY } && errors.isEmpty
}

class TangoErrors(val cells: Set<Int>, val constraints: Set<TangoConstraint>) {
    val isEmpty: Boolean get() = cells.isEmpty()
}
