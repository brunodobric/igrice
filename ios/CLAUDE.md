# Pravila za iOS dio projekta

- **Sve što je moguće ide sistemski.** Ako SwiftUI/iOS ima gotovu komponentu (TabView, NavigationStack i toolbar, Form, Picker, `.sheet`, `.alert`, gumbi s `.borderedProminent` ili `.bordered`, SF Symbols, `ContentUnavailableView`), koristi se ona. Vlastita komponenta samo kad sistemske nema ili ne može postići ono što igra traži (ploče igara, `ScoreCard`, uvodna animacija, logo).
- Boje brenda (`XOBrand`, `Theme`) i pozadina ostaju, a sistemske kontrole se obojaju preko `.tint`.
- Logika igara (Model) portira se vjerno iz `index.html`, prikaz se piše iznova.
- Odgovori i komentari na hrvatskom.
