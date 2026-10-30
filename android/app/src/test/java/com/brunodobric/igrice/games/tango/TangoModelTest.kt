package com.brunodobric.igrice.games.tango

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class TangoModelTest {
    private val n = TANGO_SIZE

    /** Ispravno riješena ploča: svaki red i stupac ima 3 X i 3 O, bez tri ista u nizu. */
    private fun assertValidSolution(b: IntArray) {
        for (k in 0 until n) {
            val row = List(n) { b[k * n + it] }
            val column = List(n) { b[it * n + k] }
            for (line in listOf(row, column)) {
                assertEquals(3, line.count { it == SUN })
                assertEquals(3, line.count { it == MOON })
                for (i in 0..n - 3) assertFalse(line[i] == line[i + 1] && line[i] == line[i + 2])
            }
        }
    }

    @Test
    fun generatedSolutionsFollowTheRules() {
        val random = Random(1)
        repeat(50) { assertValidSolution(TangoLogic.generateSolution(random)) }
    }

    @Test
    fun puzzlesAreSolvableByLogicAndMatchTheirConstraints() {
        val random = Random(42)
        repeat(30) {
            val puzzle = TangoLogic.makePuzzle(random)
            assertEquals(TangoLogic.CONSTRAINT_COUNT, puzzle.constraints.size)
            val solution = TangoLogic.logicSolve(puzzle)
            assertNotNull(solution)
            assertValidSolution(solution!!)
            // zadana polja ostaju, a svi znakovi = i × vrijede u rješenju
            puzzle.given.forEachIndexed { i, v -> if (v != EMPTY) assertEquals(v, solution[i]) }
            for (c in puzzle.constraints) assertFalse(c.isViolated(solution[c.a], solution[c.b]))
            // ploča popunjena rješenjem je riješena
            assertTrue(TangoBoard(puzzle, solution).isSolved)
            // zagonetka nešto i skriva
            assertTrue(puzzle.given.count { it == EMPTY } > 0)
        }
    }

    @Test
    fun forbiddenDetectsTriplesCountsAndConstraints() {
        val empty = TangoPuzzle(IntArray(n * n), emptyList())
        val b = IntArray(n * n)
        b[0] = SUN; b[1] = SUN
        assertTrue(TangoLogic.forbidden(b, 2, SUN, empty))     // treći X u nizu
        assertFalse(TangoLogic.forbidden(b, 2, MOON, empty))

        val c = IntArray(n * n)
        c[0] = MOON; c[2] = MOON; c[4] = MOON
        assertTrue(TangoLogic.forbidden(c, 5, MOON, empty))    // četvrti O u redu

        val withEqual = TangoPuzzle(IntArray(n * n), listOf(TangoConstraint(0, 6, isEqual = true)))
        val d = IntArray(n * n).also { it[0] = SUN }
        assertTrue(TangoLogic.forbidden(d, 6, MOON, withEqual))
        assertFalse(TangoLogic.forbidden(d, 6, SUN, withEqual))
    }

    @Test
    fun tapCyclesAndLongPressTogglesMoon() {
        val puzzle = TangoPuzzle(IntArray(n * n).also { it[0] = SUN }, emptyList())
        var board = TangoBoard(puzzle)
        board = board.cycle(1)
        assertEquals(SUN, board.values[1])
        board = board.cycle(1)
        assertEquals(MOON, board.values[1])
        board = board.cycle(1)
        assertEquals(EMPTY, board.values[1])
        board = board.toggleMoon(1)
        assertEquals(MOON, board.values[1])
        board = board.toggleMoon(1)
        assertEquals(EMPTY, board.values[1])

        // zadano polje se ne mijenja
        assertSame(board, board.cycle(0))
        // čišćenje vraća samo zadana polja
        val cleared = board.cycle(2).cycle(3).cleared()
        assertArrayEquals(puzzle.given, cleared.values)
    }

    @Test
    fun errorsMarkTriplesOvercountsAndBrokenConstraints() {
        val constraint = TangoConstraint(12, 13, isEqual = false)
        val puzzle = TangoPuzzle(IntArray(n * n), listOf(constraint))
        val values = IntArray(n * n)
        values[0] = SUN; values[1] = SUN; values[2] = SUN       // tri X u nizu
        values[12] = MOON; values[13] = MOON                    // × prekršen
        val errors = TangoBoard(puzzle, values).errors
        assertEquals(setOf(0, 1, 2, 12, 13), errors.cells)
        assertEquals(setOf(constraint), errors.constraints)

        val over = IntArray(n * n)
        for (c in listOf(0, 2, 3, 5)) over[24 + c] = MOON       // četiri O u redu 5
        assertEquals(setOf(24, 26, 27, 29), TangoBoard(puzzle, over).errors.cells)
    }

    @Test
    fun logicSolveRejectsContradictions() {
        // polje (0, 2): X bi dao trojku u redu, a O trojku u stupcu
        val b = IntArray(n * n)
        b[0] = SUN; b[1] = SUN
        b[8] = MOON; b[14] = MOON
        assertNull(TangoLogic.logicSolve(TangoPuzzle(b, emptyList())))
    }
}
