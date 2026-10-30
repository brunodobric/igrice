package com.brunodobric.igrice.shared

import android.content.Context
import androidx.core.content.edit

/**
 * Lokalno spremljeni rekordi i odabiri, pod istim ključevima kao localStorage u index.html
 * (npr. `mines-best-easy`, u milisekundama).
 */
class Records(context: Context) {
    private val prefs = context.getSharedPreferences("igrice", Context.MODE_PRIVATE)

    /** Najbolje vrijeme u ms ili null ako ga još nema. */
    fun best(key: String): Long? = prefs.getLong(key, 0L).takeIf { it > 0 }

    fun setBest(key: String, ms: Long) = prefs.edit { putLong(key, ms) }

    fun string(key: String): String? = prefs.getString(key, null)

    fun setString(key: String, value: String) = prefs.edit { putString(key, value) }
}
