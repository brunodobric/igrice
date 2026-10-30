# XO Igrice za Android

Nativna Android verzija (Kotlin, Jetpack Compose, Material 3), samo telefon, portret, Android 8.0 (API 26) ili noviji.

| Igra | Stanje |
| --- | --- |
| Minolovac | portiran (Lako, Srednje, Teško; generator bez pogađanja) |
| Tango | portiran (6 × 6, znakovi = i ×, zagonetke rješive logikom) |
| Neboderi | uskoro |
| Križić Kružić | uskoro |

## Otvaranje i pokretanje

1. U Android Studiju odaberi **File › Open** i otvori mapu `android` (ne korijen repozitorija).
2. Pričekaj da završi **Gradle sync**. Ako Studio javi da nedostaje Android SDK 35, klikni ponuđeni **Install** i pokreni sync ponovno.
3. Napravi emulator: **Tools › Device Manager › + › Create Virtual Device**, odaberi telefon (npr. Pixel 8), sliku sustava s API 35 i završi.
4. Gore u traci odaberi konfiguraciju **app** i taj emulator, pa klikni **Run** (zeleni trokut).

Testovi logike: desni klik na `app/src/test` › **Run 'Tests in …'**, ili u terminalu `./gradlew test`.

## Struktura

```
app/src/main/java/com/brunodobric/igrice/
  MainActivity.kt, IgriceApp.kt   ulaz i navigacija (TopAppBar + NavigationBar)
  Game.kt                         popis igara, pravila i savjeti
  ui/Theme.kt                     boje brenda, Material tema, ScoreCard, znakovi X i O
  ui/Components.kt                dijalog s ishodom, pravila u donjem listu, „Uskoro”
  shared/                         GameTimer (čista logika), Records (SharedPreferences)
  games/minesweeper/              MinesweeperModel.kt (logika), MinesweeperScreen.kt (prikaz)
  games/tango/                    TangoModel.kt (logika), TangoScreen.kt (prikaz)
```
