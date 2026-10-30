# Pravila za Android dio projekta

- **Sve što je moguće ide sistemski.** Ako Material 3 / Compose ima gotovu komponentu (Scaffold, TopAppBar, NavigationBar, SegmentedButton, ModalBottomSheet, AlertDialog, ListItem, IconButton, ikone iz `material-icons-core`), koristi se ona. Vlastita komponenta samo kad sistemske nema (ploče igara, `ScoreCard`, ikone igara iz index.html).
- Boje brenda (`BrandColors` u `ui/Theme.kt`) ulaze u sistemske kontrole preko Material sheme boja.
- Svaka igra ima dvije datoteke u `games/<igra>/`: `<Igra>Model.kt` (čista logika, bez Androida) i `<Igra>Screen.kt` (Compose prikaz i ViewModel).
- Logika igara portira se vjerno iz `index.html`, prikaz se piše iznova.
- Rekordi i odabiri u SharedPreferences (`shared/Records.kt`), pod istim ključevima kao localStorage na webu.
- Kod se prevodi bez upozorenja i bez nepotrebnih biblioteka.
- Odgovori i komentari na hrvatskom.
