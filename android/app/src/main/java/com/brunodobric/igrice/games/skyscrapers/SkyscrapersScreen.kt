package com.brunodobric.igrice.games.skyscrapers

import android.app.Application
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.floor

// Tijek igre

/**
 * Veza između čiste logike ([SkyscrapersBoard]) i prikaza: generiranje zagonetke u pozadini
 * (Pro zna potrajati), mjerač vremena i rekordi po razini.
 */
class SkyscrapersViewModel(application: Application) : AndroidViewModel(application) {
    private val records = Records(application)
    private val timer = GameTimer()
    private var generation: Job? = null
    private var ticker: Job? = null
    private var active = false

    var level by mutableStateOf(SkyscrapersLevel.fromKey(records.string(LEVEL_KEY)))
        private set
    /** null dok se prva zagonetka ne složi. */
    var board by mutableStateOf<SkyscrapersBoard?>(null)
        private set
    var isGenerating by mutableStateOf(false)
        private set
    var isSolved by mutableStateOf(false)
        private set
    var elapsedMs by mutableLongStateOf(0L)
        private set
    var best by mutableStateOf(records.best(bestKey(level)))
        private set
    var result by mutableStateOf<GameResult?>(null)
        private set

    init {
        newPuzzle()
    }

    /** Dodir povećava visinu, dugi pritisak je smanjuje. */
    fun step(i: Int, direction: Int) {
        val current = board ?: return
        if (isSolved || isGenerating) return
        if (!timer.hasStarted) {
            timer.start()
            if (!active) timer.pause()
            updateTicker()
        }
        play(current.step(i, direction))
    }

    fun clear() {
        val current = board ?: return
        if (isSolved || isGenerating) return
        play(current.cleared())
    }

    fun selectLevel(next: SkyscrapersLevel) {
        records.setString(LEVEL_KEY, next.key)
        level = next
        best = records.best(bestKey(next))
        newPuzzle()
    }

    fun newPuzzle() {
        generation?.cancel()
        timer.reset()
        isSolved = false
        result = null
        updateTicker()
        isGenerating = true
        val requested = level
        generation = viewModelScope.launch {
            val clues = withContext(Dispatchers.Default) { SkyscrapersLogic.makePuzzle(requested) }
            board = SkyscrapersBoard(requested, clues)
            isGenerating = false
        }
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

    private fun play(next: SkyscrapersBoard) {
        board = next
        if (next.isSolved) finish(next.level)
    }

    private fun finish(level: SkyscrapersLevel) {
        isSolved = true
        timer.pause()
        updateTicker()
        val ms = timer.elapsedMs()
        val previous = best
        val isRecord = previous == null || ms < previous
        if (isRecord) {
            records.setBest(bestKey(level), ms)
            best = ms
        }
        val message = if (isRecord) {
            "★ Novi rekord ★\nNajbolji rezultat za razinu ${level.label}!"
        } else {
            "Tvoj rekord (${level.label}) je ${GameTimer.format(previous ?: 0L)}."
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
        const val LEVEL_KEY = "sky-level"
        fun bestKey(level: SkyscrapersLevel) = "sky-best-${level.key}"
    }
}

// Prikaz

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SkyscrapersScreen(
    paused: Boolean,
    modifier: Modifier = Modifier,
    viewModel: SkyscrapersViewModel = viewModel(),
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
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
            SkyscrapersLevel.entries.forEachIndexed { index, level ->
                SegmentedButton(
                    selected = viewModel.level == level,
                    onClick = { if (viewModel.level != level) viewModel.selectLevel(level) },
                    shape = SegmentedButtonDefaults.itemShape(index, SkyscrapersLevel.entries.size),
                ) { Text(level.label) }
            }
        }

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
            viewModel.board?.let { board ->
                SkyBoard(
                    board = board,
                    enabled = !viewModel.isSolved && !viewModel.isGenerating,
                    isSolved = viewModel.isSolved,
                    available = minOf(maxWidth, maxHeight, 520.dp),
                    onStep = viewModel::step,
                )
            }
        }

        StatusLine(viewModel)

        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedButton(
                onClick = viewModel::clear,
                enabled = !viewModel.isSolved && !viewModel.isGenerating,
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
private fun StatusLine(viewModel: SkyscrapersViewModel) {
    val brand = LocalBrand.current
    val board = viewModel.board
    val (text, color) = when {
        viewModel.isGenerating || board == null -> "Slažem zagonetku…" to brand.muted
        viewModel.isSolved -> "Riješeno u ${GameTimer.format(viewModel.elapsedMs)}!" to brand.cyan
        board.hasErrors -> "Ima grešaka…" to brand.accent
        board.filled == 0 -> "${viewModel.level.hint}. Dodirni polje za visinu (1–$SKY_SIZE)." to brand.muted
        else -> "Popunjeno ${board.filled} / ${SKY_SIZE * SKY_SIZE}" to brand.muted
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

/** Ploča 7 × 7: tragovi uz rub, a u sredini 5 × 5 polja. */
@Composable
private fun SkyBoard(
    board: SkyscrapersBoard,
    enabled: Boolean,
    isSolved: Boolean,
    available: Dp,
    onStep: (Int, Int) -> Unit,
) {
    val brand = LocalBrand.current
    val padding = 10.dp
    val gap = 5.dp
    val span = SKY_SIZE + 2
    val fit = (available - padding * 2 - gap * (span - 1)) / span
    val cellSize = floor(fit.value).dp.coerceIn(28.dp, 62.dp)
    val shape = RoundedCornerShape(18.dp)

    Column(
        modifier = Modifier
            .background(brand.surface, shape)
            .border(1.dp, brand.line, shape)
            .padding(padding),
        verticalArrangement = Arrangement.spacedBy(gap),
    ) {
        for (rr in 0 until span) {
            Row(horizontalArrangement = Arrangement.spacedBy(gap)) {
                for (cc in 0 until span) {
                    val edgeRow = rr == 0 || rr == span - 1
                    val edgeColumn = cc == 0 || cc == span - 1
                    when {
                        edgeRow && edgeColumn -> Box(Modifier.size(cellSize))
                        edgeRow || edgeColumn -> {
                            val (side, i) = when {
                                rr == 0 -> Side.TOP to cc - 1
                                rr == span - 1 -> Side.BOTTOM to cc - 1
                                cc == 0 -> Side.LEFT to rr - 1
                                else -> Side.RIGHT to rr - 1
                            }
                            ClueView(board.clues[side][i], (side to i) in board.badClues, side, cellSize)
                        }
                        else -> {
                            val index = (rr - 1) * SKY_SIZE + (cc - 1)
                            SkyCellView(
                                value = board.values[index],
                                isError = index in board.badCells,
                                isSolved = isSolved,
                                enabled = enabled,
                                size = cellSize,
                                description = "Redak $rr, stupac $cc",
                                onTap = { onStep(index, +1) },
                                onLongPress = { onStep(index, -1) },
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ClueView(clue: Int, isBad: Boolean, side: Side, size: Dp) {
    val brand = LocalBrand.current
    val where = when (side) {
        Side.TOP -> "odozgo"
        Side.BOTTOM -> "odozdo"
        Side.LEFT -> "slijeva"
        Side.RIGHT -> "zdesna"
    }
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(size)
            .semantics { if (clue != 0) contentDescription = "Trag $where: $clue" + if (isBad) ", prekršen" else "" },
    ) {
        if (clue != 0) {
            Text(
                "$clue",
                color = if (isBad) brand.accent else brand.gold,
                fontWeight = FontWeight.ExtraBold,
                fontSize = with(LocalDensity.current) { (size * 0.45f).toSp() },
            )
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun SkyCellView(
    value: Int,
    isError: Boolean,
    isSolved: Boolean,
    enabled: Boolean,
    size: Dp,
    description: String,
    onTap: () -> Unit,
    onLongPress: () -> Unit,
) {
    val brand = LocalBrand.current
    val shape = RoundedCornerShape(10.dp)
    val outline = when {
        isError -> brand.accent
        isSolved -> brand.cyan.copy(alpha = 0.6f)
        else -> brand.line
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(size)
            .clip(shape)
            .background(brand.cell)
            .border(1.5.dp, outline, shape)
            .combinedClickable(
                enabled = enabled,
                role = Role.Button,
                onLongClickLabel = "Smanji visinu",
                onLongClick = onLongPress,
                onClickLabel = "Povećaj visinu",
                onClick = onTap,
            )
            .semantics { contentDescription = "$description, " + if (value == 0) "prazno" else "visina $value" },
    ) {
        // stupac koji raste s visinom nebodera
        if (value != 0) {
            Box(
                Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .fillMaxHeight(value / SKY_SIZE.toFloat())
                    .background(brand.cyan.copy(alpha = 0.25f)),
            )
            Text(
                "$value",
                color = brand.text,
                fontWeight = FontWeight.ExtraBold,
                fontSize = with(LocalDensity.current) { (size * 0.5f).toSp() },
            )
        }
    }
}
