package com.brunodobric.igrice

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
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
import com.brunodobric.igrice.ui.ComingSoon
import com.brunodobric.igrice.ui.LocalBrand
import com.brunodobric.igrice.ui.RulesSheet

/**
 * Glavni ekran: sistemska gornja traka (naslov igre i Pravila) i donja traka s četiri igre.
 * Stanje igara živi u ViewModelima, pa se ne gubi pri prelasku između kartica.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IgriceApp() {
    var game by rememberSaveable { mutableStateOf(Game.MINESWEEPER) }
    var showRules by rememberSaveable { mutableStateOf(false) }

    Box(Modifier.fillMaxSize().background(LocalBrand.current.backgroundBrush)) {
        Scaffold(
            containerColor = Color.Transparent,
            topBar = {
                CenterAlignedTopAppBar(
                    title = { Text(game.title) },
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
                Game.MINESWEEPER -> MinesweeperScreen(paused = showRules, modifier = modifier)
                else -> ComingSoon(game, modifier)
            }
        }
    }

    if (showRules) RulesSheet(game) { showRules = false }
}
