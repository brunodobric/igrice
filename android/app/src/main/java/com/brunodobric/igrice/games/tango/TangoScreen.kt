package com.brunodobric.igrice.games.tango

import android.app.Application
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.currentStateAsState
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.brunodobric.igrice.shared.GameTimer
import com.brunodobric.igrice.shared.Records
import com.brunodobric.igrice.ui.GameResult
import com.brunodobric.igrice.ui.GameResultDialog
import com.brunodobric.igrice.ui.LocalBrand
import com.brunodobric.igrice.ui.ScoreCard
import com.brunodobric.igrice.ui.drawO
import com.brunodobric.igrice.ui.drawX
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.math.floor

// Tijek igre

/**
 * Veza između čiste logike ([TangoBoard]) i prikaza: mjerač vremena, odgođeni prikaz
 * grešaka i rekord. Živi koliko i aktivnost, pa partija preživi promjenu kartice.
 */
class TangoViewModel(application: Application) : AndroidViewModel(application) {
    private val records = Records(application)
    private val timer = GameTimer()
    private var ticker: Job? = null
    private var errorDelay: Job? = null
    private var active = false

    var board by mutableStateOf(TangoBoard(TangoLogic.makePuzzle()))
        private set
    var isSolved by mutableStateOf(false)
        private set
    /** Greške se pokazuju tek 2 s nakon zadnjeg poteza, da brza ispravka (X → O) ne bljesne crveno. */
    var showErrors by mutableStateOf(false)
        private set
    var elapsedMs by mutableLongStateOf(0L)
        private set
    var best by mutableStateOf(records.best(BEST_KEY))
        private set
    var result by mutableStateOf<GameResult?>(null)
        private set

    fun tap(i: Int) = place(i) { board.cycle(i) }

    fun longPress(i: Int) = place(i) { board.toggleMoon(i) }

    fun clear() {
        if (isSolved) return
        board = board.cleared()
        refresh()
    }

    fun newPuzzle() {
        errorDelay?.cancel()
        timer.reset()
        board = TangoBoard(TangoLogic.makePuzzle())
        isSolved = false
        showErrors = false
        result = null
        updateTicker()
    }

    fun dismissResult() {
        result = null
    }

    /** Igra je (ne)aktivna: na ekranu, bez donjeg lista i aplikacija u prvom planu. */
    fun setActive(isActive: Boolean) {
        active = isActive
        if (isActive && !isSolved) timer.resume() else timer.pause()
        updateTicker()
    }

    private inline fun place(i: Int, move: () -> TangoBoard) {
        if (isSolved || board.isGiven(i)) return
        if (!timer.hasStarted) {
            timer.start()
            if (!active) timer.pause()
        }
        board = move()
        refresh()
    }

    private fun refresh() {
        errorDelay?.cancel()
        showErrors = false
        if (board.isSolved) {
            finish()
            return
        }
        if (!board.errors.isEmpty) {
            errorDelay = viewModelScope.launch {
                delay(2000)
                showErrors = true
            }
        }
        updateTicker()
    }

    private fun finish() {
        isSolved = true
        timer.pause()
        updateTicker()
        val ms = timer.elapsedMs()
        val previous = best
        val isRecord = previous == null || ms < previous
        if (isRecord) {
            records.setBest(BEST_KEY, ms)
            best = ms
        }
        val message = if (isRecord) {
            "★ Novi rekord ★\nNovi najbolji rezultat!"
        } else {
            "Tvoj rekord je ${GameTimer.format(previous ?: 0L)}."
        }
        result = GameResult("Riješeno!", "Vrijeme ${GameTimer.format(ms)}\n$message")
    }

    /** Prikaz vremena osvježava se četiri puta u sekundi, samo dok mjerač radi. */
    private fun updateTicker() {
        elapsedMs = timer.elapsedMs()
        if (timer.isRunning) {
            if (ticker?.isActive == true) return
            ticker = viewModelScope.launch {
                while (isActive) {
                    elapsedMs = timer.elapsedMs()
                    delay(250)
                }
            }
        } else {
            ticker?.cancel()
            ticker = null
        }
    }

    private companion object {
        const val BEST_KEY = "tango-best-ms"
    }
}

// Prikaz

@Composable
fun TangoScreen(
    paused: Boolean,
    modifier: Modifier = Modifier,
    viewModel: TangoViewModel = viewModel(),
) {
    val brand = LocalBrand.current

    // mjerač stoji dok je otvoren donji list, druga kartica ili je aplikacija u pozadini
    val lifecycleState by LocalLifecycleOwner.current.lifecycle.currentStateAsState()
    val active = !paused && lifecycleState.isAtLeast(Lifecycle.State.RESUMED)
    DisposableEffect(active) {
        viewModel.setActive(active)
        onDispose { viewModel.setActive(false) }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ScoreCard("Vrijeme", GameTimer.format(viewModel.elapsedMs), brand.cyan, Modifier.weight(1f))
            ScoreCard("Rekord", viewModel.best?.let { GameTimer.format(it) } ?: "—", brand.gold, Modifier.weight(1f))
        }

        BoxWithConstraints(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            contentAlignment = Alignment.Center,
        ) {
            TangoBoardView(
                board = viewModel.board,
                errors = if (viewModel.showErrors) viewModel.board.errors else null,
                isSolved = viewModel.isSolved,
                available = minOf(maxWidth, maxHeight, 520.dp),
                onTap = viewModel::tap,
                onLongPress = viewModel::longPress,
            )
        }

        StatusLine(viewModel)

        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedButton(
                onClick = viewModel::clear,
                enabled = !viewModel.isSolved,
                modifier = Modifier.weight(1f),
            ) { Text("Očisti") }
            FilledIconButton(onClick = viewModel::newPuzzle) {
                Icon(Icons.Filled.Refresh, contentDescription = "Nova zagonetka")
            }
        }
    }

    GameResultDialog(
        result = viewModel.result,
        onNewGame = viewModel::newPuzzle,
        onDismiss = viewModel::dismissResult,
    )
}

@Composable
private fun StatusLine(viewModel: TangoViewModel) {
    val brand = LocalBrand.current
    val board = viewModel.board
    val total = TANGO_SIZE * TANGO_SIZE
    val (text, color) = when {
        viewModel.isSolved -> "Riješeno u ${GameTimer.format(viewModel.elapsedMs)}!" to brand.cyan
        viewModel.showErrors -> "Ima grešaka…" to brand.accent
        board.filled == board.puzzle.given.count { it != EMPTY } ->
            "Dodirni polje: X → O → prazno" to brand.muted
        else -> "Popunjeno ${board.filled} / $total" to brand.muted
    }
    Text(
        text,
        color = color,
        style = MaterialTheme.typography.bodyMedium,
        fontWeight = if (color == brand.muted) FontWeight.Normal else FontWeight.Bold,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun TangoBoardView(
    board: TangoBoard,
    errors: TangoErrors?,
    isSolved: Boolean,
    available: Dp,
    onTap: (Int) -> Unit,
    onLongPress: (Int) -> Unit,
) {
    val brand = LocalBrand.current
    val padding = 10.dp
    val gap = 6.dp
    val fit = (available - padding * 2 - gap * (TANGO_SIZE - 1)) / TANGO_SIZE
    val cellSize = floor(fit.value).dp.coerceIn(32.dp, 68.dp)
    val markerSize = 22.dp
    val shape = RoundedCornerShape(18.dp)

    Box(
        modifier = Modifier
            .background(brand.surface, shape)
            .border(1.dp, brand.line, shape)
            .padding(padding),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(gap)) {
            for (row in 0 until TANGO_SIZE) {
                Row(horizontalArrangement = Arrangement.spacedBy(gap)) {
                    for (column in 0 until TANGO_SIZE) {
                        val index = row * TANGO_SIZE + column
                        TangoCellView(
                            value = board.values[index],
                            isGiven = board.isGiven(index),
                            isError = errors?.cells?.contains(index) == true,
                            isSolved = isSolved,
                            size = cellSize,
                            description = "Redak ${row + 1}, stupac ${column + 1}",
                            onTap = { onTap(index) },
                            onLongPress = { onLongPress(index) },
                        )
                    }
                }
            }
        }

        // znakovi = i × na sredini razmaka između dvaju polja
        for (constraint in board.puzzle.constraints) {
            val row = constraint.a / TANGO_SIZE
            val column = constraint.a % TANGO_SIZE
            val step = cellSize + gap
            val (x, y) = if (constraint.isHorizontal) {
                step * column + cellSize + gap / 2 to step * row + cellSize / 2
            } else {
                step * column + cellSize / 2 to step * row + cellSize + gap / 2
            }
            ConstraintMarker(
                isEqual = constraint.isEqual,
                isBad = errors?.constraints?.contains(constraint) == true,
                modifier = Modifier
                    .offset(x - markerSize / 2, y - markerSize / 2)
                    .size(markerSize),
            )
        }
    }
}

@Composable
private fun ConstraintMarker(isEqual: Boolean, isBad: Boolean, modifier: Modifier) {
    val brand = LocalBrand.current
    val color = if (isBad) brand.accent else brand.muted
    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .background(brand.background.first(), CircleShape)
            .border(1.5.dp, color, CircleShape)
            .clearAndSetSemantics { },
    ) {
        Text(
            if (isEqual) "=" else "×",
            color = if (isBad) brand.accent else brand.text,
            fontWeight = FontWeight.SemiBold,
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun TangoCellView(
    value: Int,
    isGiven: Boolean,
    isError: Boolean,
    isSolved: Boolean,
    size: Dp,
    description: String,
    onTap: () -> Unit,
    onLongPress: () -> Unit,
) {
    val brand = LocalBrand.current
    val shape = RoundedCornerShape(10.dp)
    val fill = when {
        isError -> brand.accent.copy(alpha = 0.12f).compositeOver(brand.cell)
        isGiven -> brand.surfaceRaised
        else -> brand.cell
    }
    val outline = when {
        isError -> brand.accent
        isSolved -> brand.cyan.copy(alpha = 0.6f)
        else -> fill
    }
    val label = when (value) {
        SUN -> "X"
        MOON -> "O"
        else -> "prazno"
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(size)
            .clip(shape)
            .background(fill)
            .border(2.dp, outline, shape)
            .combinedClickable(
                enabled = !isGiven && !isSolved,
                role = Role.Button,
                onLongClickLabel = "Postavi ili ukloni O",
                onLongClick = onLongPress,
                onClick = onTap,
            )
            .semantics {
                contentDescription = "$description, $label" + if (isGiven) ", zadano" else ""
            },
    ) {
        val weight = 3.2f
        when (value) {
            SUN -> Canvas(Modifier.size(size * 0.78f)) { drawX(brand.accent, weight) }
            MOON -> Canvas(Modifier.size(size * 0.78f)) { drawO(brand.cyan, weight) }
        }
    }
}
