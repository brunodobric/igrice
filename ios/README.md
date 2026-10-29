# XO Igrice za iOS

SwiftUI aplikacija (iOS 17+, iPhone, portret) koja portira igre iz `index.html`.

## Pokretanje

Xcode projekt se generira iz `project.yml` alatom [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
cd ios
xcodegen
open Igrice.xcodeproj
```

Bundle ID u `project.yml` (`com.brunodobric.igrice`) po potrebi promijeni, a u Xcodeu odaberi svoj Team u Signing & Capabilities.

Ako već imaš vlastiti Xcode projekt, povuci mapu `Igrice/` u njega i obriši `IgriceApp.swift` koji se sudara s postojećim ulazom.

## Struktura

- `Igrice/IgriceApp.swift` ulaz, uvodna animacija pa `ContentView`
- `Igrice/ContentView.swift` gornji red, igra, plutajuća traka, prozorčići
- `Igrice/Theme.swift` boje, `ScoreCard`, gumbi, `ResultOverlay`, odabir teme
- `Igrice/Brand/` logo i uvodna animacija
- `Igrice/Shared/` dijelovi zajednički igrama
- `Igrice/Games/<Igra>/` Model (čista logika) i View po igri
