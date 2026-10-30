package com.brunodobric.igrice

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import com.brunodobric.igrice.games.minesweeper.MinesweeperScreen
import com.brunodobric.igrice.games.skyscrapers.SkyscrapersScreen
import com.brunodobric.igrice.games.tango.TangoScreen
import com.brunodobric.igrice.games.tictactoe.TicTacToeScreen
import com.brunodobric.igrice.ui.LocalBrand
import com.brunodobric.igrice.ui.RulesSheet
import com.brunodobric.igrice.ui.SettingsSheet
import com.brunodobric.igrice.ui.SplashOverlay
import com.brunodobric.igrice.ui.ThemePreference

/**
 * Glavni ekran: sistemska gornja traka (Postavke, naslov igre, Pravila) i donja traka s četiri igre.
 * Pri pokretanju preko svega ide uvodna animacija.
 * Stanje igara živi u ViewModelima, pa se ne gubi pri prelasku između kartica.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IgriceApp(themePreference: ThemePreference, onThemePreferenceChange: (ThemePreference) -> Unit) {
    var game by rememberSaveable { mutableStateOf(Game.TIC_TAC_TOE) }
    var showRules by rememberSaveable { mutableStateOf(false) }
    var showSettings by rememberSaveable { mutableStateOf(false) }
    var showSplash by rememberSaveable { mutableStateOf(true) }
    val paused = showRules || showSettings || showSplash

    Box(Modifier.fillMaxSize().background(LocalBrand.current.backgroundBrush)) {
        Scaffold(
            containerColor = Color.Transparent,
            topBar = {
                CenterAlignedTopAppBar(
                    title = { Text(game.title) },
                    navigationIcon = {
                        IconButton(onClick = { showSettings = true }) {
                            Icon(Icons.Outlined.Settings, contentDescription = "Postavke")
                        }
                    },
                    actions = {
                        IconButton(onClick = { showRules = true }) {
                            Icon(Icons.Outlined.Info, contentDescription = "Pravila")
                        }
                    },
                    colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = Color.Transparent),
                )
            },
            bottomBar = {
                NavigationBar {
                    Game.entries.forEach { item ->
                        NavigationBarItem(
                            selected = item == game,
                            onClick = { game = item },
                            icon = { Icon(painterResource(item.icon), contentDescription = null) },
                            label = { Text(item.tabLabel, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                        )
                    }
                }
            },
        ) { padding ->
            val modifier = Modifier.padding(padding)
            when (game) {
                Game.MINESWEEPER -> MinesweeperScreen(paused = paused, modifier = modifier)
                Game.TANGO -> TangoScreen(paused = paused, modifier = modifier)
                Game.SKYSCRAPERS -> SkyscrapersScreen(paused = paused, modifier = modifier)
                Game.TIC_TAC_TOE -> TicTacToeScreen(modifier)
            }
        }

        if (showSplash) SplashOverlay { showSplash = false }
    }

    if (showRules) RulesSheet(game) { showRules = false }
    if (showSettings) {
        SettingsSheet(themePreference, onThemePreferenceChange) { showSettings = false }
    }
}
