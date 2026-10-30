package com.brunodobric.igrice.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Boje brenda; vrijednosti prate CSS varijable iz index.html (tamna i svijetla tema).
 * Sistemske kontrole (Material 3) dobivaju ih preko sheme boja u [IgriceTheme].
 */
@Immutable
data class BrandColors(
    val background: List<Color>,
    val surface: Color,         // ploha: kartice, ploča
    val surfaceRaised: Color,   // istaknuto: aktivno
    val line: Color,            // rub; i zatvoreno polje
    val cell: Color,            // otvoreno polje na ploči
    val text: Color,
    val muted: Color,
    val accent: Color,          // koralj, X
    val cyan: Color,            // O
    val gold: Color,
    val numbers: List<Color>,   // brojke u Minolovcu: nikad boje X-a ni O-a
) {
    val backgroundBrush: Brush get() = Brush.linearGradient(background, Offset.Zero, Offset.Infinite)

    fun mineNumber(n: Int): Color = numbers[n.coerceIn(1, 8) - 1]
}

private val DarkBrand = BrandColors(
    background = listOf(Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)),
    surface = Color(0xFF20426B),
    surfaceRaised = Color(0xFF2B5283),
    line = Color(0xFF315076),
    cell = Color(0xFF0B2A4F),
    text = Color(0xFFF1F4FA),
    muted = Color(0xFFA8B8D4),
    accent = Color(0xFFE94560),
    cyan = Color(0xFF53D8FB),
    gold = Color(0xFFF0A500),
    numbers = listOf(
        Color(0xFF8EA6FF), Color(0xFF5BE49B), Color(0xFFFF9F6B), Color(0xFFB892FF),
        Color(0xFFFFD166), Color(0xFFC7D0E8), Color(0xFFF1F4FA), Color(0xFFA3AECB),
    ),
)

private val LightBrand = BrandColors(
    background = listOf(Color(0xFFF7F8FC), Color(0xFFEDF1F9), Color(0xFFE1E9F6)),
    surface = Color(0xFFFFFFFF),
    surfaceRaised = Color(0xFFE6EAF3),
    line = Color(0xFFD5DBE8),
    cell = Color(0xFFF3F5FA),
    text = Color(0xFF141A2B),
    muted = Color(0xFF56607A),
    accent = Color(0xFFD2354F),
    cyan = Color(0xFF0A86AD),
    gold = Color(0xFFB07400),
    numbers = listOf(
        Color(0xFF3D5FD6), Color(0xFF1E8A5C), Color(0xFFC4561A), Color(0xFF6B3FC9),
        Color(0xFF8A6D00), Color(0xFF4D5B7C), Color(0xFF141A2B), Color(0xFF56607A),
    ),
)

val LocalBrand = staticCompositionLocalOf { DarkBrand }

/** Material 3 tema obojana bojama brenda; tamna ili svijetla prema postavci sustava. */
@Composable
fun IgriceTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val brand = if (darkTheme) DarkBrand else LightBrand
    val base = if (darkTheme) darkColorScheme() else lightColorScheme()
    val scheme = base.copy(
        primary = brand.accent,
        onPrimary = Color.White,
        primaryContainer = brand.accent,
        onPrimaryContainer = Color.White,
        secondary = brand.cyan,
        tertiary = brand.gold,
        secondaryContainer = brand.surfaceRaised,
        onSecondaryContainer = brand.text,
        background = brand.background.first(),
        onBackground = brand.text,
        surface = brand.background.first(),
        onSurface = brand.text,
        onSurfaceVariant = brand.muted,
        surfaceContainerLowest = brand.surface,
        surfaceContainerLow = brand.surface,
        surfaceContainer = brand.surface,
        surfaceContainerHigh = brand.surface,
        surfaceContainerHighest = brand.surfaceRaised,
        outline = brand.line,
        outlineVariant = brand.line,
        error = brand.accent,
    )
    CompositionLocalProvider(LocalBrand provides brand) {
        MaterialTheme(colorScheme = scheme, content = content)
    }
}

// Kartica s brojkom

/**
 * Mala kartica s naslovom i vrijednošću (mine, vrijeme, rekord, bodovi).
 * Istaknuta kartica (igrač na redu) dobiva rub u boji vrijednosti.
 */
@Composable
fun ScoreCard(
    title: String,
    value: String,
    tint: Color,
    modifier: Modifier = Modifier,
    highlighted: Boolean = false,
) {
    val brand = LocalBrand.current
    val shape = RoundedCornerShape(16.dp)
    Column(
        modifier = modifier
            .heightIn(min = 56.dp)
            .background(if (highlighted) brand.surfaceRaised else brand.surface, shape)
            .border(if (highlighted) 2.dp else 1.dp, if (highlighted) tint else brand.line, shape)
            .clearAndSetSemantics { contentDescription = "$title: $value" },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            title.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = brand.muted,
        )
        Text(
            value,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            color = tint,
        )
    }
}

// Znakovi X i O (XO_SVG iz index.html, mreža 24 × 24)

/** X: krakovi od 6,5 do 17,5; debljina poteza `weight` od 24 jedinice. */
fun DrawScope.drawX(color: Color, weight: Float = 2.9f) {
    val s = size.minDimension / 24f
    val stroke = s * weight
    fun p(x: Float, y: Float) = Offset((size.width - 24 * s) / 2 + x * s, (size.height - 24 * s) / 2 + y * s)
    drawLine(color, p(6.5f, 6.5f), p(17.5f, 17.5f), stroke, StrokeCap.Round)
    drawLine(color, p(17.5f, 6.5f), p(6.5f, 17.5f), stroke, StrokeCap.Round)
}

/** O: krug polumjera 6,4. */
fun DrawScope.drawO(color: Color, weight: Float = 2.9f) {
    val s = size.minDimension / 24f
    drawCircle(color, radius = 6.4f * s, style = Stroke(width = s * weight))
}
