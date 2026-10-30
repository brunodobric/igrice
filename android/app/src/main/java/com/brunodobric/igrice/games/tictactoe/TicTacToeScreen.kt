package com.brunodobric.igrice.games.tictactoe

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import com.brunodobric.igrice.ui.GameResult
import com.brunodobric.igrice.ui.GameResultDialog
import com.brunodobric.igrice.ui.LocalBrand
import com.brunodobric.igrice.ui.ScoreCard
import com.brunodobric.igrice.ui.drawO
import com.brunodobric.igrice.ui.drawX
import kotlin.math.floor

// Tijek igre

/** Ploča i bodovi za dva igrača na istom uređaju. Živi koliko i aktivnost. */
class TicTacToeViewModel : ViewModel() {
    var board by mutableStateOf(TicTacToeBoard())
        private set
    var scores by mutableStateOf(TicTacToeScores())
        private set
    var result by mutableStateOf<GameResult?>(null)
        private set

    fun play(i: Int) {
        val next = board.play(i)
        if (next === board) return
        board = next
        next.outcome?.let { outcome ->
            scores = scores.adding(outcome)
            result = when (outcome) {
                TicTacToeOutcome.Draw -> GameResult("Remi!", "Nitko nije pobijedio ovaj put.")
                is TicTacToeOutcome.Win -> GameResult("Pobijedio ${outcome.winner.label}!", "Čestitke!")
            }
        }
    }

    fun newGame() {
        board = TicTacToeBoard()
        result = null
    }

    /** Briše bodove i počinje novu partiju. */
    fun resetScores() {
        scores = TicTacToeScores()
        newGame()
    }

    fun dismissResult() {
        result = null
    }
}

// Prikaz

@Composable
fun TicTacToeScreen(modifier: Modifier = Modifier, viewModel: TicTacToeViewModel = viewModel()) {
    val brand = LocalBrand.current
    val board = viewModel.board
    val scores = viewModel.scores

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ScoreCard(
                "Igrač 1 (X)", "${scores.x}", brand.accent, Modifier.weight(1f),
                highlighted = !board.isOver && board.current == Mark.X,
            )
            ScoreCard("Remi", "${scores.draws}", brand.gold, Modifier.weight(1f))
            ScoreCard(
                "Igrač 2 (O)", "${scores.o}", brand.cyan, Modifier.weight(1f),
                highlighted = !board.isOver && board.current == Mark.O,
            )
        }

        BoxWithConstraints(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            contentAlignment = Alignment.Center,
        ) {
            TicTacToeBoardView(
                board = board,
                available = minOf(maxWidth, maxHeight, 460.dp),
                onTap = viewModel::play,
            )
        }

        StatusLine(board)

        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedButton(onClick = viewModel::resetScores, modifier = Modifier.weight(1f)) {
                Text("Resetiraj bodove")
            }
            FilledIconButton(onClick = viewModel::newGame) {
                Icon(Icons.Filled.Refresh, contentDescription = "Nova igra")
            }
        }
    }

    GameResultDialog(
        result = viewModel.result,
        onNewGame = viewModel::newGame,
        onDismiss = viewModel::dismissResult,
    )
}

@Composable
private fun StatusLine(board: TicTacToeBoard) {
    val brand = LocalBrand.current
    fun color(mark: Mark) = if (mark == Mark.X) brand.accent else brand.cyan
    val (text, color) = when (val outcome = board.outcome) {
        TicTacToeOutcome.Draw -> "Remi!" to brand.gold
        is TicTacToeOutcome.Win -> "${outcome.winner.label} pobijedio!" to color(outcome.winner)
        null -> "Na redu je ${board.current.label}" to color(board.current)
    }
    Text(
        text,
        color = color,
        style = MaterialTheme.typography.bodyMedium,
        fontWeight = FontWeight.Bold,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun TicTacToeBoardView(board: TicTacToeBoard, available: Dp, onTap: (Int) -> Unit) {
    val brand = LocalBrand.current
    val padding = 15.dp
    val gap = 10.dp
    val fit = (available - padding * 2 - gap * 2) / 3
    val cellSize = floor(fit.value).dp.coerceIn(56.dp, 130.dp)
    val shape = RoundedCornerShape(18.dp)
    val winLine = (board.outcome as? TicTacToeOutcome.Win)?.line.orEmpty()

    Column(
        modifier = Modifier
            .background(brand.surface, shape)
            .border(1.dp, brand.line, shape)
            .padding(padding),
        verticalArrangement = Arrangement.spacedBy(gap),
    ) {
        for (row in 0 until 3) {
            Row(horizontalArrangement = Arrangement.spacedBy(gap)) {
                for (column in 0 until 3) {
                    val index = row * 3 + column
                    TicTacToeCellView(
                        mark = board.cells[index],
                        isWinner = index in winLine,
                        enabled = !board.isOver && board.cells[index] == null,
                        size = cellSize,
                        description = "Redak ${row + 1}, stupac ${column + 1}",
                        onTap = { onTap(index) },
                    )
                }
            }
        }
    }
}

@Composable
private fun TicTacToeCellView(
    mark: Mark?,
    isWinner: Boolean,
    enabled: Boolean,
    size: Dp,
    description: String,
    onTap: () -> Unit,
) {
    val brand = LocalBrand.current
    val shape = RoundedCornerShape(16.dp)
    val tint = when (mark) {
        Mark.X -> brand.accent
        Mark.O -> brand.cyan
        null -> Color.Transparent
    }
    val fill = when {
        mark == null -> brand.cell
        isWinner -> tint.copy(alpha = 0.22f).compositeOver(brand.cell)
        else -> tint.copy(alpha = 0.09f).compositeOver(brand.cell)
    }
    val outline = when {
        mark == null -> Color.Transparent
        isWinner -> tint
        else -> tint.copy(alpha = 0.4f)
    }
    // dobitna polja lagano pulsiraju (pulse-win u index.html)
    val pulse = if (isWinner) {
        rememberInfiniteTransition(label = "pobjeda").animateFloat(
            initialValue = 1f,
            targetValue = 1.06f,
            animationSpec = infiniteRepeatable(tween(600), RepeatMode.Reverse),
            label = "puls",
        ).value
    } else {
        1f
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(size)
            .scale(pulse)
            .clip(shape)
            .background(fill)
            .border(2.dp, outline, shape)
            .clickable(enabled = enabled, role = Role.Button, onClick = onTap)
            .semantics {
                contentDescription = "$description, " + when (mark) {
                    Mark.X -> "X"
                    Mark.O -> "O"
                    null -> "prazno"
                }
            },
    ) {
        when (mark) {
            Mark.X -> Canvas(Modifier.size(size * 0.7f)) { drawX(tint) }
            Mark.O -> Canvas(Modifier.size(size * 0.7f)) { drawO(tint) }
            null -> Unit
        }
    }
}
