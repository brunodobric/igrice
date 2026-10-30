package com.brunodobric.igrice.games.minesweeper

import android.app.Application
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.graphics.Color
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
import com.brunodobric.igrice.ui.drawO
import com.brunodobric.igrice.ui.drawX
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.floor

// Tijek igre

/**
 * Veza između čiste logike ([MinesweeperBoard]) i prikaza: mjerač vremena, generiranje
 * ploče u pozadini i rekordi. Živi koliko i aktivnost, pa partija preživi promjenu kartice.
 */
class MinesweeperViewModel(application: Application) : AndroidViewModel(application) {
    private val records = Records(application)
    private val timer = GameTimer()
    private var generation: Job? = null
    private var ticker: Job? = null
    private var active = false

    var board by mutableStateOf(MinesweeperBoard(MinesweeperLevel.fromKey(records.string(LEVEL_KEY))))
        private set
    var flagMode by mutableStateOf(false)
    var isGenerating by mutableStateOf(false)
        private set
    var elapsedMs by mutableLongStateOf(0L)
        private set
    var best by mutableStateOf(records.best(bestKey(board.level)))
        private set
    var result by mutableStateOf<GameResult?>(null)
        private set

    fun tap(i: Int) {
        if (flagMode) toggleFlag(i) else reveal(i)
    }

    /** Postavlja ili skida zastavicu. Zastavica prije prvog dodira pokreće mjerač. */
    fun toggleFlag(i: Int) {
        if (board.isOver || board.cells[i].isRevealed) return
        if (!timer.hasStarted && board.isFirstMove) startTimer()
        board = board.toggleFlag(i)
    }

    /** Prvi dodir: raspored mina se traži u pozadini (do 2 s), da sučelje ne zastane. */
    fun reveal(i: Int) {
        val cell = board.cells[i]
        if (board.isOver || cell.isFlagged || cell.isRevealed) return
        if (!board.isFirstMove) {
            play(board.reveal(i))
            return
        }
        if (isGenerating) return
        isGenerating = true
        val level = board.level
        generation = viewModelScope.launch {
            val layout = withContext(Dispatchers.Default) { MinesweeperLogic.makeLayout(level, i) }
            isGenerating = false
            if (board.level == level && board.isFirstMove) {
                startTimer()
                play(board.reveal(i, layout))
            }
        }
    }

    fun selectLevel(level: MinesweeperLevel) {
        records.setString(LEVEL_KEY, level.key)
        newGame(level)
    }

    fun newGame(level: MinesweeperLevel = board.level) {
        generation?.cancel()
        isGenerating = false
        timer.reset()
        board = MinesweeperBoard(level)
        best = records.best(bestKey(level))
        result = null
        updateTicker()
    }

    fun dismissResult() {
        result = null
    }

    /** Igra je (ne)aktivna: na ekranu, bez donjeg lista i aplikacija u prvom planu. */
    fun setActive(isActive: Boolean) {
        active = isActive
        if (isActive && !board.isOver) timer.resume() else timer.pause()
        updateTicker()
    }

    private fun startTimer() {
        timer.start()
        if (!active) timer.pause()
        updateTicker()
    }

    private fun play(next: MinesweeperBoard) {
        val wasOver = board.isOver
        board = next
        val outcome = next.outcome
        if (!wasOver && outcome != null) finish(outcome)
    }

    private fun finish(outcome: MinesweeperOutcome) {
        timer.pause()
        updateTicker()
        val ms = timer.elapsedMs()
        val time = GameTimer.format(ms)
        result = when (outcome) {
            is MinesweeperOutcome.Lost ->
                GameResult("Kraj igre", "Bum! Nagazio si minu.\nVrijeme $time\nPokušaj ponovno!")
            MinesweeperOutcome.Won -> {
                val level = board.level
                val previous = best
                val isRecord = previous == null || ms < previous
                if (isRecord) {
                    records.setBest(bestKey(level), ms)
                    best = ms
                }
                val message = if (isRecord) {
                    "★ Novi rekord! ★\nNajbolji rezultat za razinu ${level.label}!"
                } else {
                    "Rekord (${level.label}): ${GameTimer.format(previous ?: 0L)}."
                }
                GameResult("Pobjeda!", "Vrijeme $time\n$message")
            }
        }
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
        const val LEVEL_KEY = "mines-level"
        fun bestKey(level: MinesweeperLevel) = "mines-best-${level.key}"
    }
}

// Prikaz

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MinesweeperScreen(
    paused: Boolean,
    modifier: Modifier = Modifier,
    viewModel: MinesweeperViewModel = viewModel(),
) {
    val brand = LocalBrand.current
    val board = viewModel.board

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
            MinesweeperLevel.entries.forEachIndexed { index, level ->
                SegmentedButton(
                    selected = board.level == level,
                    onClick = { if (board.level != level) viewModel.selectLevel(level) },
                    shape = SegmentedButtonDefaults.itemShape(index, MinesweeperLevel.entries.size),
                ) { Text(level.label) }
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ScoreCard("Mine", "${board.minesLeft}", brand.cyan, Modifier.weight(1f))
            ScoreCard("Vrijeme", GameTimer.format(viewModel.elapsedMs), brand.cyan, Modifier.weight(1f))
            ScoreCard("Rekord", viewModel.best?.let { GameTimer.format(it) } ?: "—", brand.gold, Modifier.weight(1f))
        }

        BoxWithConstraints(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            contentAlignment = Alignment.Center,
        ) {
            MinesBoard(
                board = board,
                available = minOf(maxWidth, maxHeight, 560.dp),
                onTap = viewModel::tap,
                onLongPress = viewModel::toggleFlag,
            )
        }

        StatusLine(board, viewModel.isGenerating)

        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SingleChoiceSegmentedButtonRow(Modifier.weight(1f)) {
                listOf(false to "Otkrij", true to "Zastavica").forEachIndexed { index, (flag, label) ->
                    SegmentedButton(
                        selected = viewModel.flagMode == flag,
                        onClick = { viewModel.flagMode = flag },
                        shape = SegmentedButtonDefaults.itemShape(index, 2),
                    ) { Text(label) }
                }
            }
            FilledIconButton(onClick = { viewModel.newGame() }) {
                Icon(Icons.Filled.Refresh, contentDescription = "Nova igra")
            }
        }
    }

    GameResultDialog(
        result = viewModel.result,
        onNewGame = { viewModel.newGame() },
        onDismiss = viewModel::dismissResult,
    )
}

@Composable
private fun StatusLine(board: MinesweeperBoard, isGenerating: Boolean) {
    val brand = LocalBrand.current
    val outcome = board.outcome
    val (text, color) = when {
        outcome is MinesweeperOutcome.Lost -> "Bum! Nagazio si minu." to brand.accent
        outcome == MinesweeperOutcome.Won -> "Očišćeno!" to brand.cyan
        isGenerating -> "Slažem ploču…" to brand.muted
        board.isFirstMove -> "Dodirni bilo koje polje za početak." to brand.muted
        board.mayNeedGuess -> "Napomena: ova ploča možda traži pogađanje." to brand.gold
        else -> "Rješivo logikom — bez pogađanja." to brand.cyan
    }
    Text(
        text,
        color = color,
        style = MaterialTheme.typography.bodyMedium,
        fontWeight = if (outcome != null) FontWeight.Bold else FontWeight.Normal,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth(),
    )
}

/** Najveća veličina polja po razini (size u LEVELS iz index.html). */
private val MinesweeperLevel.maxCell: Dp
    get() = when (this) {
        MinesweeperLevel.EASY -> 48.dp
        MinesweeperLevel.MEDIUM -> 38.dp
        MinesweeperLevel.HARD -> 30.dp
    }

@Composable
private fun MinesBoard(
    board: MinesweeperBoard,
    available: Dp,
    onTap: (Int) -> Unit,
    onLongPress: (Int) -> Unit,
) {
    val brand = LocalBrand.current
    val padding = 7.dp
    val gap = 2.dp
    val fit = (available - padding * 2 - gap * (board.cols - 1)) / board.cols
    val cellSize = floor(fit.value).dp.coerceIn(12.dp, board.level.maxCell)
    val shape = RoundedCornerShape(18.dp)
    val exploded = (board.outcome as? MinesweeperOutcome.Lost)?.exploded

    Column(
        modifier = Modifier
            .background(brand.surface, shape)
            .border(1.dp, brand.line, shape)
            .padding(padding),
        verticalArrangement = Arrangement.spacedBy(gap),
    ) {
        for (row in 0 until board.rows) {
            Row(horizontalArrangement = Arrangement.spacedBy(gap)) {
                for (column in 0 until board.cols) {
                    val index = row * board.cols + column
                    MineCellView(
                        cell = board.cells[index],
                        isExploded = exploded == index,
                        isWrongFlag = board.isWrongFlag(index),
                        enabled = !board.isOver,
                        size = cellSize,
                        description = "Redak ${row + 1}, stupac ${column + 1}",
                        onTap = { onTap(index) },
                        onLongPress = { onLongPress(index) },
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MineCellView(
    cell: MineCell,
    isExploded: Boolean,
    isWrongFlag: Boolean,
    enabled: Boolean,
    size: Dp,
    description: String,
    onTap: () -> Unit,
    onLongPress: () -> Unit,
) {
    val brand = LocalBrand.current
    val fill = when {
        isExploded -> brand.accent
        isWrongFlag -> brand.accent.copy(alpha = 0.14f)
        cell.isRevealed -> brand.cell
        else -> brand.line
    }
    val value = when {
        cell.isFlagged && !cell.isRevealed -> "zastavica"
        !cell.isRevealed -> "zatvoreno"
        cell.isMine -> "mina"
        cell.adjacent == 0 -> "prazno"
        else -> "${cell.adjacent}"
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(size)
            .clip(RoundedCornerShape(4.dp))
            .background(fill)
            .combinedClickable(
                enabled = enabled && !cell.isRevealed,
                role = Role.Button,
                onLongClickLabel = if (cell.isFlagged) "Skini zastavicu" else "Postavi zastavicu",
                onLongClick = onLongPress,
                onClick = onTap,
            )
            .semantics { contentDescription = "$description, $value" },
    ) {
        when {
            cell.isFlagged && !cell.isRevealed ->
                Canvas(Modifier.size(size * 0.72f)) { drawX(brand.accent, weight = 3.4f) }
            cell.isRevealed && cell.isMine ->
                Canvas(Modifier.size(size * 0.72f)) {
                    drawO(if (isExploded) Color.White else brand.cyan, weight = 3.4f)
                }
            cell.isRevealed && cell.adjacent > 0 -> Text(
                "${cell.adjacent}",
                color = brand.mineNumber(cell.adjacent),
                fontWeight = FontWeight.ExtraBold,
                fontSize = with(LocalDensity.current) { (size * 0.55f).toSp() },
            )
        }
    }
}
