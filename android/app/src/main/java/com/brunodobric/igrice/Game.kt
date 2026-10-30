package com.brunodobric.igrice

import androidx.annotation.DrawableRes

/** Četiri igre u aplikaciji. Tekstovi pravila preuzeti su iz `INFO` u index.html. */
enum class Game(val title: String, @DrawableRes val icon: Int) {
    TIC_TAC_TOE("Križić Kružić", R.drawable.ic_game_tictactoe),
    TANGO("Tango", R.drawable.ic_game_tango),
    MINESWEEPER("Minolovac", R.drawable.ic_game_minesweeper),
    SKYSCRAPERS("Neboderi", R.drawable.ic_game_skyscrapers);

    /** Kratak naziv za donju traku, gdje dulji naslov ne stane. */
    val tabLabel: String
        get() = if (this == TIC_TAC_TOE) "Križić" else title

    val rules: List<String>
        get() = when (this) {
            TIC_TAC_TOE -> listOf(
                "Igrač 1 (X) i Igrač 2 (O) naizmjence postavljaju svoj znak na prazno polje.",
                "Pobjeđuje tko prvi složi tri svoja znaka u redu, stupcu ili dijagonali.",
                "Ako su sva polja popunjena, a nitko nije pobijedio, igra je neriješena (remi).",
            )
            TANGO -> listOf(
                "Popuni ploču znakovima X i O: u svakom redu i stupcu mora biti po 3 X i 3 O.",
                "Više od dva ista znaka ne smiju stajati jedan do drugoga u redu ni u stupcu.",
                "Znak = između dva polja znači da su ista, a znak × da su različita.",
                "Svaka zagonetka ima jedno rješenje i može se riješiti logikom.",
            )
            MINESWEEPER -> listOf(
                "Otkrij sva polja na kojima nema mine.",
                "Broj na polju kaže koliko mina ima u osam susjednih polja.",
                "Pronađene mine označi zastavicom X: prebaci način na Zastavica ili dugo pritisni polje.",
                "Dodir na minu završava igru, a pobjeda je kad su otkrivena sva sigurna polja.",
            )
            SKYSCRAPERS -> listOf(
                "U svaki red i stupac upiši visine nebodera od 1 do 5, svaku točno jednom.",
                "Broj uz rub kaže koliko se nebodera vidi iz tog smjera.",
                "Viši neboder zaklanja sve niže iza sebe.",
                "Pogrešna polja i tragovi označe se crveno.",
            )
        }

    val hint: String
        get() = when (this) {
            TIC_TAC_TOE -> "Gore je istaknut igrač koji je na redu. Bodovi se zbrajaju dok ih ne resetiraš."
            TANGO -> "Dodir mijenja polje: prazno → X → O → prazno. Dugi pritisak odmah postavlja O. Zadana polja se ne mogu mijenjati."
            MINESWEEPER -> "Prvi dodir je uvijek siguran, a ploča se u pravilu može riješiti bez pogađanja. Brojač gore pokazuje koliko je mina još neoznačeno."
            SKYSCRAPERS -> "Dodir povećava visinu (1 → 5 → prazno), a dugi pritisak je smanjuje."
        }
}
