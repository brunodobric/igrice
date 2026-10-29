import Foundation

/// Razina težine (Minolovac) ili način (Neboderi), kako se prikazuje u postavkama.
struct LevelOption: Identifiable, Hashable {
    let id: String
    let label: String
    let hint: String
}

/// Četiri igre u aplikaciji. Tekstovi pravila preuzeti su iz `INFO` u index.html.
enum Game: String, CaseIterable, Identifiable {
    case ticTacToe, tango, minesweeper, skyscrapers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ticTacToe: "Križić Kružić"
        case .tango: "Tango"
        case .minesweeper: "Minolovac"
        case .skyscrapers: "Neboderi"
        }
    }

    var rules: [String] {
        switch self {
        case .ticTacToe: [
            "Igrač 1 (X) i Igrač 2 (O) naizmjence postavljaju svoj znak na prazno polje.",
            "Pobjeđuje tko prvi složi tri svoja znaka u redu, stupcu ili dijagonali.",
            "Ako su sva polja popunjena, a nitko nije pobijedio, igra je neriješena (remi)."
        ]
        case .tango: [
            "Popuni ploču znakovima X i O: u svakom redu i stupcu mora biti po 3 X i 3 O.",
            "Više od dva ista znaka ne smiju stajati jedan do drugoga u redu ni u stupcu.",
            "Znak = između dva polja znači da su ista, a znak × da su različita.",
            "Svaka zagonetka ima jedno rješenje i može se riješiti logikom."
        ]
        case .minesweeper: [
            "Otkrij sva polja na kojima nema mine.",
            "Broj na polju kaže koliko mina ima u osam susjednih polja.",
            "Pronađene mine označi zastavicom X: prebaci način na Zastavica ili dugo pritisni polje.",
            "Dodir na minu završava igru, a pobjeda je kad su otkrivena sva sigurna polja."
        ]
        case .skyscrapers: [
            "U svaki red i stupac upiši visine nebodera od 1 do 5, svaku točno jednom.",
            "Broj uz rub kaže koliko se nebodera vidi iz tog smjera.",
            "Viši neboder zaklanja sve niže iza sebe.",
            "Pogrešna polja i tragovi označe se crveno."
        ]
        }
    }

    var hint: String {
        switch self {
        case .ticTacToe:
            "Gore je istaknut igrač koji je na redu. Bodovi se zbrajaju dok ih ne resetiraš."
        case .tango:
            "Dodir mijenja polje: prazno → X → O → prazno. Dugi pritisak odmah postavlja O. Zadana polja se ne mogu mijenjati."
        case .minesweeper:
            "Prvi dodir je uvijek siguran, a ploča se u pravilu može riješiti bez pogađanja. Brojač gore pokazuje koliko je mina još neoznačeno."
        case .skyscrapers:
            "Dodir povećava visinu (1 → 5 → prazno), a dugi pritisak je smanjuje."
        }
    }

    /// Ključ pod kojim se pamti odabrana razina; nil ako igra nema razina.
    var levelKey: String? {
        switch self {
        case .minesweeper: "mines-level"
        case .skyscrapers: "sky-mode"
        default: nil
        }
    }

    var defaultLevel: String {
        switch self {
        case .minesweeper: "easy"
        case .skyscrapers: "classic"
        default: ""
        }
    }

    var levels: [LevelOption] {
        switch self {
        case .minesweeper: [
            LevelOption(id: "easy", label: "Lako", hint: "8 × 8 polja, 10 mina"),
            LevelOption(id: "medium", label: "Srednje", hint: "12 × 12 polja, 30 mina"),
            LevelOption(id: "hard", label: "Teško", hint: "16 × 16 polja, 50 mina")
        ]
        case .skyscrapers: [
            LevelOption(id: "easy", label: "Lagano", hint: "Prikazani su svi tragovi"),
            LevelOption(id: "classic", label: "Klasično", hint: "Rješivo logikom, bez pogađanja"),
            LevelOption(id: "pro", label: "Pro", hint: "Jedno rješenje, ali može tražiti pogađanje")
        ]
        default: []
        }
    }
}
