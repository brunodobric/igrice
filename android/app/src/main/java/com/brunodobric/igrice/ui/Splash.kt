package com.brunodobric.igrice.ui

import android.provider.Settings
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

// Logo (mreža 100 × 100, kao XOLogo.swift i sp-woven u index.html)

private fun DrawScope.unit(): Float = size.minDimension / 100f

private fun DrawScope.at(x: Float, y: Float): Offset {
    val s = unit()
    return Offset((size.width - 100 * s) / 2 + x * s, (size.height - 100 * s) / 2 + y * s)
}

/** X iz loga: krakovi od 22 do 78. */
private fun DrawScope.logoX(color: Color, weight: Float, blendMode: BlendMode = BlendMode.SrcOver) {
    val stroke = weight * unit()
    drawLine(color, at(22f, 22f), at(78f, 78f), stroke, StrokeCap.Round, blendMode = blendMode)
    drawLine(color, at(78f, 22f), at(22f, 78f), stroke, StrokeCap.Round, blendMode = blendMode)
}

/** O iz loga: krug polumjera 22. */
private fun DrawScope.logoO(color: Color, weight: Float, blendMode: BlendMode = BlendMode.SrcOver) {
    drawCircle(color, radius = 22 * unit(), center = at(50f, 50f), style = Stroke(weight * unit()), blendMode = blendMode)
}

/** Crta samo unutar dvaju kvadrata 25 × 25 (gore lijevo i dolje desno, ili obrnuto). */
private fun DrawScope.inSquares(mainDiagonal: Boolean, block: DrawScope.() -> Unit) {
    val corners = if (mainDiagonal) listOf(22f to 22f, 53f to 53f) else listOf(53f to 22f, 22f to 53f)
    for ((x, y) in corners) {
        val rect = Rect(at(x, y), at(x + 25, y + 25))
        clipRect(rect.left, rect.top, rect.right, rect.bottom) { block() }
    }
}

/**
 * Isprepleteni logo: O prelazi preko X-a gore lijevo i dolje desno, X preko O-a gore desno
 * i dolje lijevo. Prekid od 21 jedinice izbriše se u sloju znaka koji je ispod.
 */
@Composable
fun XOLogo(modifier: Modifier = Modifier) {
    val brand = LocalBrand.current
    Box(modifier.clearAndSetSemantics { contentDescription = "XO Igrice" }) {
        Canvas(Modifier.matchParentSize().graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }) {
            logoO(brand.cyan, 12f)
            inSquares(mainDiagonal = false) { logoX(Color.Black, 21f, BlendMode.Clear) }
        }
        Canvas(Modifier.matchParentSize().graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }) {
            logoX(brand.accent, 12f)
            inSquares(mainDiagonal = true) { logoO(Color.Black, 21f, BlendMode.Clear) }
        }
    }
}

// Uvodna animacija

/**
 * Uvod (2 s, kao SplashView.swift i .splash u index.html): X dolazi slijeva, O zdesna, sudare se,
 * isprepletu u logo, logo se digne i ispod se pojavi ime. Dodir ga preskače.
 * Kad su animacije u sustavu isključene, prikazuje samo logo i ime.
 */
@Composable
fun SplashOverlay(onFinish: () -> Unit) {
    val brand = LocalBrand.current
    val context = LocalContext.current
    val reduceMotion = remember {
        Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
    val scope = rememberCoroutineScope()

    val arrive = remember { Animatable(0f) }     // X i O su doletjeli
    val burst = remember { Animatable(0f) }      // cijan val se širi i nestaje
    val squash = remember { Animatable(0f) }     // spljoštenje u sudaru
    val named = remember { Animatable(0f) }      // logo gore, ime vidljivo
    val fade = remember { Animatable(1f) }       // pretapanje u igru
    var burstVisible by remember { mutableStateOf(false) }
    var woven by remember { mutableStateOf(false) }
    var finished by remember { mutableStateOf(false) }

    fun finish() {
        if (finished) return
        finished = true
        scope.launch {
            fade.animateTo(0f, tween(250, easing = FastOutSlowInEasing))
            onFinish()
        }
    }

    LaunchedEffect(Unit) {
        if (reduceMotion) {
            arrive.snapTo(1f)
            named.snapTo(1f)
            woven = true
            delay(1200)
            finish()
            return@LaunchedEffect
        }
        // 0,00 s: ulazak
        launch { arrive.animateTo(1f, spring(dampingRatio = 0.6f, stiffness = 180f)) }
        // 0,50 s: sudar
        delay(500)
        burstVisible = true
        launch { burst.animateTo(1f, tween(450, easing = LinearOutSlowInEasing)) }
        launch {
            squash.animateTo(1f, tween(100))
            squash.animateTo(0f, spring(dampingRatio = 0.5f, stiffness = Spring.StiffnessMediumLow))
        }
        // 0,55 s: isprepletanje
        delay(50)
        woven = true
        // 0,95 s: logo se diže, ime ulazi
        delay(400)
        launch { named.animateTo(1f, tween(450, easing = FastOutSlowInEasing)) }
        // 1,75 s: pretapanje u igru
        delay(800)
        finish()
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .fillMaxSize()
            .graphicsLayer { alpha = fade.value }
            .background(brand.backgroundBrush)
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { finish() },
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Box(
                Modifier
                    .size(150.dp)
                    .offset { IntOffset(0, (36.dp.toPx() * (1 - named.value)).roundToInt()) }
                    .graphicsLayer {
                        scaleX = 1 + 0.14f * squash.value
                        scaleY = 1 - 0.1f * squash.value
                    },
            ) {
                if (burstVisible) {
                    Canvas(
                        Modifier.matchParentSize().graphicsLayer {
                            val scale = 0.7f + 1.2f * burst.value
                            scaleX = scale
                            scaleY = scale
                            alpha = 0.8f * (1 - burst.value)
                        },
                    ) {
                        drawCircle(brand.cyan, radius = 30 * unit(), style = Stroke(3 * unit()))
                    }
                }
                if (woven) {
                    XOLogo(Modifier.matchParentSize())
                } else {
                    val progress = arrive.value
                    val appear = (progress / 0.3f).coerceIn(0f, 1f)
                    Canvas(
                        Modifier.matchParentSize().graphicsLayer {
                            translationX = -260.dp.toPx() * (1 - progress)
                            rotationZ = -200f * (1 - progress)
                            alpha = appear
                        },
                    ) { logoX(brand.accent, 12f) }
                    Canvas(
                        Modifier.matchParentSize().graphicsLayer {
                            translationX = 260.dp.toPx() * (1 - progress)
                            val scale = 0.55f + 0.45f * progress
                            scaleX = scale
                            scaleY = scale
                            alpha = appear
                        },
                    ) { logoO(brand.cyan, 12f) }
                }
            }
            Text(
                buildAnnotatedString {
                    withStyle(SpanStyle(color = brand.accent)) { append("X") }
                    withStyle(SpanStyle(color = brand.cyan)) { append("O") }
                    append(" Igrice")
                },
                color = brand.text,
                fontSize = 36.sp,
                fontWeight = FontWeight.Black,
                modifier = Modifier.graphicsLayer {
                    alpha = named.value
                    translationY = 10.dp.toPx() * (1 - named.value)
                },
            )
        }
    }
}
