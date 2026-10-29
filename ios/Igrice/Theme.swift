import SwiftUI

/// Zajednički izgled igara: boje, kartice za rezultat, gumbi i prozor s ishodom.
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
    static let onAccent = Color.white

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

// MARK: - Gumbi

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, 28)
            .frame(minHeight: 48)
            .background(Capsule().fill(Theme.accent))
            .shadow(color: Theme.accent.opacity(0.4), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .background(Capsule().fill(Theme.surface))
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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

// MARK: - Prozor s ishodom

enum ResultMark {
    case xo
    case emoji(String)
}

/// Prozor koji se prikaže na kraju igre: znak, naslov, vrijeme, oznaka rekorda, poruka i gumb.
struct ResultOverlay: View {
    var mark: ResultMark = .xo
    let title: String
    var time: String?
    var recordBadge: String?
    var message: String?
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            Theme.scrim.ignoresSafeArea()

            VStack(spacing: 12) {
                markView
                Text(title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.text)
                if let time {
                    Text(time)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.cyan)
                }
                if let recordBadge {
                    Text(recordBadge)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.gold.opacity(0.15)))
                }
                if let message {
                    Text(message)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                Button(buttonTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: 28).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.line, lineWidth: 1))
            .padding(24)
        }
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private var markView: some View {
        switch mark {
        case .xo:
            XOLogo().frame(width: 72, height: 72)
        case .emoji(let symbol):
            Text(symbol).font(.system(size: 60))
        }
    }
}

#Preview {
    ResultOverlay(title: "Riješeno!", time: "01:23", recordBadge: "Novi rekord!",
                  message: "Bravo, zagonetka je riješena!", buttonTitle: "Nova zagonetka") { }
        .background(XOBrand.background)
}
