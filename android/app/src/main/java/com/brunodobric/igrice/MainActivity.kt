package com.brunodobric.igrice

import android.app.UiModeManager
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.brunodobric.igrice.shared.Records
import com.brunodobric.igrice.ui.IgriceTheme
import com.brunodobric.igrice.ui.ThemePreference

class MainActivity : ComponentActivity() {
    private lateinit var records: Records

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        records = Records(this)
        enableEdgeToEdge()
        setContent {
            var preference by remember {
                mutableStateOf(ThemePreference.fromKey(records.string(ThemePreference.STORAGE_KEY)))
            }
            val dark = preference.isDark(isSystemInDarkTheme())

            // ikone statusne i navigacijske trake prate odabranu temu, ne samo sustav
            DisposableEffect(dark) {
                enableEdgeToEdge(
                    statusBarStyle = SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT) { dark },
                    navigationBarStyle = SystemBarStyle.auto(LIGHT_SCRIM, DARK_SCRIM) { dark },
                )
                onDispose {}
            }

            IgriceTheme(darkTheme = dark) {
                IgriceApp(
                    themePreference = preference,
                    onThemePreferenceChange = {
                        preference = it
                        saveThemePreference(it)
                    },
                )
            }
        }
    }

    /**
     * Sprema odabir. Od Androida 12 javlja ga i sustavu, pa i sistemski uvodni ekran
     * pri sljedećem pokretanju dobije odabranu temu.
     */
    private fun saveThemePreference(preference: ThemePreference) {
        records.setString(ThemePreference.STORAGE_KEY, preference.key)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(UiModeManager::class.java).setApplicationNightMode(
                when (preference) {
                    ThemePreference.AUTO -> UiModeManager.MODE_NIGHT_AUTO
                    ThemePreference.DARK -> UiModeManager.MODE_NIGHT_YES
                    ThemePreference.LIGHT -> UiModeManager.MODE_NIGHT_NO
                },
            )
        }
    }

    private companion object {
        // iste vrijednosti kao zadane u enableEdgeToEdge()
        val LIGHT_SCRIM = Color.argb(0xE6, 0xFF, 0xFF, 0xFF)
        val DARK_SCRIM = Color.argb(0x80, 0x1B, 0x1B, 0x1B)
    }
}
