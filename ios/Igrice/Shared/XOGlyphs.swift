import SwiftUI

/// X kao u XO_SVG iz index.html: mreža 24 × 24, krakovi od 6,5 do 17,5.
struct XGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path()
        path.move(to: point(6.5, 6.5)); path.addLine(to: point(17.5, 17.5))
        path.move(to: point(17.5, 6.5)); path.addLine(to: point(6.5, 17.5))
        return path
    }
}

/// O kao u XO_SVG: krug polumjera 6,4 u mreži 24 × 24.
struct OGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        return Path(ellipseIn: CGRect(x: rect.minX + 5.6 * s, y: rect.minY + 5.6 * s, width: 12.8 * s, height: 12.8 * s))
    }
}

/// Znak X ili O, veličine kao `.glyph` u index.html (potez 2,9 od 24 jedinice; u Minolovcu 3,4).
struct MarkGlyph: View {
    let isX: Bool
    var side: CGFloat
    var weight: CGFloat = 2.9
    var color: Color?

    var body: some View {
        let style = StrokeStyle(lineWidth: side * weight / 24, lineCap: .round)
        let tint = color ?? (isX ? Theme.accent : Theme.cyan)
        Group {
            if isX {
                XGlyph().stroke(tint, style: style)
            } else {
                OGlyph().stroke(tint, style: style)
            }
        }
        .frame(width: side, height: side)
    }
}
