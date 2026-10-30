package com.brunodobric.igrice.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brunodobric.igrice.Game
import kotlinx.coroutines.delay

/** Ishod igre za sistemski dijalog. */
data class GameResult(val title: String, val message: String)

/**
 * Sistemski dijalog s ishodom, pola sekunde nakon kraja igre (da se vidi završna ploča).
 * „Nova igra” pokreće novu partiju, „Zatvori” ostavlja ploču da se pogleda.
 */
@Composable
fun GameResultDialog(result: GameResult?, onNewGame: () -> Unit, onDismiss: () -> Unit) {
    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(result) {
        visible = false
        if (result != null) {
            delay(500)
            visible = true
        }
    }
    if (result == null || !visible) return
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(result.title) },
        text = { Text(result.message) },
        confirmButton = { TextButton(onClick = onNewGame) { Text("Nova igra") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Zatvori") } },
    )
}

/** Pravila i savjet za odabranu igru, u sistemskom donjem listu. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RulesSheet(game: Game, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .verticalScroll(rememberScrollState())
                .padding(bottom = 16.dp),
        ) {
            Text(
                game.title,
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
            )
            game.rules.forEachIndexed { index, rule ->
                ListItem(
                    headlineContent = { Text(rule) },
                    leadingContent = {
                        Text(
                            "${index + 1}.",
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary,
                        )
                    },
                    colors = ListItemDefaults.colors(containerColor = Color.Transparent),
                )
            }
            Text(
                game.hint,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
            )
        }
    }
}

/** Postavke u sistemskom donjem listu: zasad samo tema (Auto, Tamna, Svijetla). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSheet(
    themePreference: ThemePreference,
    onThemePreferenceChange: (ThemePreference) -> Unit,
    onDismiss: () -> Unit,
) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            Modifier.padding(start = 24.dp, end = 24.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Postavke", style = MaterialTheme.typography.titleLarge)
            Text(
                "Tema",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                ThemePreference.entries.forEachIndexed { index, option ->
                    SegmentedButton(
                        selected = option == themePreference,
                        onClick = { onThemePreferenceChange(option) },
                        shape = SegmentedButtonDefaults.itemShape(index, ThemePreference.entries.size),
                    ) { Text(option.label) }
                }
            }
            Text(
                "Auto prati tamni način rada na telefonu.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
