# Priprema za App Store

Što je već napravljeno u projektu, što treba napraviti u Xcodeu i App Store Connectu te gotovi tekstovi.

## Već u projektu

- Ikona 1024 px (`Assets.xcassets/AppIcon`), bez prozirnosti.
- `PrivacyInfo.xcprivacy`: aplikacija ne prati korisnike i ne prikuplja podatke; deklarirano je samo korištenje UserDefaults (razlog CA92.1, za rekorde i spremljene igre).
- Kategorija: Igre, podkategorija Puzzle (`public.app-category.puzzle-games`).
- Samo iPhone, samo portret, iOS 17+.
- Sve ostaje na uređaju: nema računa, mreže ni reklama.

## Što napraviti u Xcodeu

1. Target Igrice, Signing & Capabilities: odaberi svoj Team (Apple Developer račun, 99 USD godišnje).
2. Postavi vlastiti Bundle Identifier (sada `com.brunodobric.igrice` u `project.yml`; ako ga promijeniš, promijeni i u `IgriceTests`).
3. General: Display Name "XO Igrice", Version 1.0, Build 1 (za svaki novi upload povećaj Build).
4. Product, Archive, pa Distribute App, App Store Connect, Upload. Prije toga Product, Test (Cmd+U) mora proći.
5. Provjeri na pravom iPhoneu: tamna i svijetla tema, uvod, sve četiri igre, zaključavanje ekrana usred igre pa povratak.

## App Store Connect

| Polje | Prijedlog |
| --- | --- |
| Naziv | XO Igrice |
| Podnaslov (30 znakova) | Četiri logičke igre u džepu |
| Kategorija | Igre, Puzzle (druga: Igre, Društvene igre) |
| Dobna ocjena | 4+ (bez nasilja, reklama i kupnji) |
| Cijena | Besplatno |
| Privatnost | "Data Not Collected" |
| Ključne riječi (100 znakova) | križić kružić,tango,minolovac,neboderi,logičke igre,zagonetke,puzzle,sudoku |
| Support URL | potrebna stranica ili repozitorij s kontaktom (npr. GitHub) |
| Export compliance | Aplikacija ne koristi šifriranje: odaberi "None of the algorithms mentioned above" |

### Opis

XO Igrice su četiri klasične igre u jednoj aplikaciji, bez reklama i bez interneta.

Križić Kružić: igra za dva igrača, s bodovima koji se zbrajaju.

Tango: popuni ploču znakovima X i O. Svaka zagonetka ima jedno rješenje i može se riješiti logikom, bez pogađanja.

Minolovac: tri razine težine. Prvi dodir je uvijek siguran, a ploče se u pravilu mogu riješiti bez pogađanja.

Neboderi: popuni ploču 5×5 visinama od 1 do 5 prema tragovima uz rub. Tri načina: Lagano, Klasično i Pro.

Mjeri vrijeme, pamti tvoje rekorde na uređaju i čuva nedovršenu igru kad izađeš iz aplikacije. Podržava tamnu i svijetlu temu te VoiceOver.

### Što je novo (verzija 1.0)

Prvo izdanje.

## Snimke zaslona

Obavezne su za iPhone 6,9" (1320 × 2868 px). Predlažem pet snimki, u tamnoj temi: uvodna animacija, Križić Kružić, Tango, Minolovac, Neboderi. Snimi ih u simulatoru (iPhone 16 Pro Max): Cmd+S sprema snimku zaslona na radnu površinu.

## Prije slanja na pregled

- [ ] Cmd+U prolazi
- [ ] Provjera na pravom uređaju
- [ ] Snimke zaslona učitane
- [ ] Support URL i opis uneseni
- [ ] Build učitan i odabran u App Store Connectu
