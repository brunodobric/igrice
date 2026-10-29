import SwiftUI

/// Zajednički izgled igara: boje, kartica za rezultat i odabir teme.
/// Pravilo projekta: gdje postoji sistemska kontrola, koristi se ona (vidi ios/CLAUDE.md).
/// Vrijednosti prate CSS varijable iz index.html (tamna i svijetla tema).
enum Theme {
    static let surface = dynamicColor(dark: 0x20426B, light: 0xFFFFFF)         // ploha: gumbi, ploča, prozorčići
    static let surfaceRaised = dynamicColor(dark: 0x2B5283, light: 0xE6EAF3)   // istaknuto: aktivno
    static let line = dynamicColor(dark: 0x315076, light: 0xD5DBE8)            // rub
    static let muted = dynamicColor(dark: 0xA8B8D4, light: 0x56607A)
    static let gold = dynamicColor(dark: 0xF0A500, light: 0xB07400)
    static let cell = dynamicColor(dark: 0x0B2A4F, light: 0xF3F5FA)            // polje na ploči

    static let text = XOBrand.text
    static let accent = XOBrand.x
    static let cyan = XOBrand.o

    static var glass: Color { surface.opacity(0.8) }
    static var scrim: Color { Color.black.opacity(0.5) }
}

/// Odabir teme koji se pamti pod istim ključem kao u web verziji.
enum ThemePreference: String, CaseIterable {
    case auto, dark, light

    static let storageKey = "igrice-theme"

    var label: String {
        switch self {
        case .auto: "Auto"
        case .dark: "Tamna"
        case .light: "Svijetla"
        }
    }

    /// nil znači da se slijedi postavka sustava.
    var colorScheme: ColorScheme? {
        switch self {
        case .auto: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

// MARK: - Kartica s brojkom

/// Mala kartica s naslovom i vrijednošću (bodovi, mine, vrijeme, rekord).
struct ScoreCard: View {
    let title: String
    let value: String
    var tint: Color = Theme.text
    var isActive = false

    var body: some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isActive ? tint : Theme.line, lineWidth: isActive ? 2 : 1))
        .accessibilityElement(children: .combine)
    }
}
