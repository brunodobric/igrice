package com.brunodobric.igrice.games.skyscrapers

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class SkyscrapersModelTest {
    private val n = SKY_SIZE

    private fun assertLatinSquare(b: IntArray) {
        for (k in 0 until n) {
            assertEquals((1..n).toSet(), SkyscrapersLogic.row(b, k).toSet())
            assertEquals((1..n).toSet(), SkyscrapersLogic.column(b, k).toSet())
        }
    }

    @Test
    fun visibleCountsTallerBuildings() {
        assertEquals(5, SkyscrapersLogic.visible(intArrayOf(1, 2, 3, 4, 5)))
        assertEquals(1, SkyscrapersLogic.visible(intArrayOf(5, 1, 2, 3, 4)))
        assertEquals(3, SkyscrapersLogic.visible(intArrayOf(2, 1, 4, 3, 5)))
    }

    @Test
    fun generatedSolutionsAreLatinSquares() {
        val random = Random(3)
        repeat(50) { assertLatinSquare(SkyscrapersLogic.generateSolution(random)) }
    }

    @Test
    fun easyShowsEveryClueAndIsSolvableByLogic() {
        val random = Random(5)
        repeat(10) {
            val clues = SkyscrapersLogic.makePuzzle(SkyscrapersLevel.EASY, random)
            assertEquals(4 * n, clues.shown)
            assertNotNull(SkyscrapersLogic.logicSolve(clues))
        }
    }

    @Test
    fun classicIsSolvableByLogicWithFewerClues() {
        val random = Random(42)
        repeat(10) {
            val clues = SkyscrapersLogic.makePuzzle(SkyscrapersLevel.CLASSIC, random)
            assertTrue(clues.shown < 4 * n)
            val solution = SkyscrapersLogic.logicSolve(clues)
            assertNotNull(solution)
            assertLatinSquare(solution!!)
            // rješenje vrijedi i jedino je
            assertTrue(SkyscrapersBoard(SkyscrapersLevel.CLASSIC, clues, solution).isSolved)
            assertEquals(1, SkyscrapersLogic.countSolutions(clues, 2))
        }
    }

    @Test
    fun proHasExactlyOneSolution() {
        val random = Random(7)
        repeat(3) {
            val clues = SkyscrapersLogic.makePuzzle(SkyscrapersLevel.PRO, random)
            assertEquals(1, SkyscrapersLogic.countSolutions(clues, 2))
        }
    }

    @Test
    fun computedCluesMatchTheSolution() {
        val solution = SkyscrapersLogic.generateSolution(Random(11))
        val clues = SkyscrapersLogic.computeClues(solution)
        assertTrue(SkyscrapersBoard(SkyscrapersLevel.EASY, clues, solution).isSolved)
    }

    @Test
    fun stepCyclesHeightsBothWays() {
        val clues = SkyscrapersLogic.computeClues(SkyscrapersLogic.generateSolution(Random(1)))
        var board = SkyscrapersBoard(SkyscrapersLevel.CLASSIC, clues)
        board = board.step(0, +1)
        assertEquals(1, board.values[0])
        board = board.step(0, -1).step(0, -1)
        assertEquals(5, board.values[0])
        board = board.step(0, +1)
        assertEquals(0, board.values[0])
        assertEquals(0, board.step(3, +1).cleared().filled)
    }

    @Test
    fun errorsMarkDuplicatesAndBrokenClues() {
        val clues = SkyscrapersLogic.computeClues(SkyscrapersLogic.generateSolution(Random(2)))
        clues.left[0] = 5
        val values = IntArray(n * n)
        values[0] = 2; values[1] = 2
        val duplicate = SkyscrapersBoard(SkyscrapersLevel.CLASSIC, clues, values)
        assertEquals(setOf(0, 1), duplicate.badCells)
        assertTrue(duplicate.badClues.isEmpty())   // red još nije pun

        val full = IntArray(n * n)
        intArrayOf(5, 4, 3, 2, 1).copyInto(full)   // vidi se 1, a trag kaže 5
        val broken = SkyscrapersBoard(SkyscrapersLevel.CLASSIC, clues, full)
        assertTrue(broken.badCells.isEmpty())
        assertTrue((Side.LEFT to 0) in broken.badClues)
        assertFalse(broken.isSolved)
    }
}
