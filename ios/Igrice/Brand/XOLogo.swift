import SwiftUI
import UIKit

// MARK: - Boje brenda (dizajn paket XO Igrice)

/// Boje za uvod i logo. Same se prilagođavaju tamnoj i svijetloj temi.
enum XOBrand {
    static let x = dynamicColor(dark: 0xE94560, light: 0xD2354F)       // koralj, X
    static let o = dynamicColor(dark: 0x53D8FB, light: 0x0A86AD)       // cijan, O
    static let text = dynamicColor(dark: 0xF1F4FA, light: 0x141A2B)
    static let bgTop = dynamicColor(dark: 0x0F3460, light: 0xF7F8FC)
    static let bgMid = dynamicColor(dark: 0x0F3460, light: 0xEDF1F9)
    static let bgBottom = dynamicColor(dark: 0x0F3460, light: 0xE1E9F6)

    static var background: LinearGradient {
        LinearGradient(colors: [bgTop, bgMid, bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

func uiColor(_ hex: UInt32) -> UIColor {
    UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
}

func dynamicColor(dark: UInt32, light: UInt32) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ? uiColor(dark) : uiColor(light) })
}

// MARK: - Oblici (mreža 100 × 100, kao u logu)

/// X iz loga: krakovi od 22 do 78, crta se s .round krajevima.
struct XMark: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 100
        let ox = rect.midX - 50 * s, oy = rect.midY - 50 * s
        var path = Path()
        path.move(to: CGPoint(x: ox + 22 * s, y: oy + 22 * s))
        path.addLine(to: CGPoint(x: ox + 78 * s, y: oy + 78 * s))
        path.move(to: CGPoint(x: ox + 78 * s, y: oy + 22 * s))
        path.addLine(to: CGPoint(x: ox + 22 * s, y: oy + 78 * s))
        return path
    }
}

/// O iz loga: krug polumjera 22.
struct OMark: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 100
        return Path(ellipseIn: CGRect(x: rect.midX - 22 * s, y: rect.midY - 22 * s, width: 44 * s, height: 44 * s))
    }
}

/// Isprepleteni logo: O prelazi preko X-a gore lijevo i dolje desno,
/// X preko O-a gore desno i dolje lijevo. Prekidi su prozirni.
struct XOLogo: View {
    var xColor: Color = XOBrand.x
    var oColor: Color = XOBrand.o

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 100
            ctx.translateBy(x: (size.width - 100 * s) / 2, y: (size.height - 100 * s) / 2)
            ctx.scaleBy(x: s, y: s)

            let unit = CGRect(x: 0, y: 0, width: 100, height: 100)
            let ring = OMark().path(in: unit)
            let cross = XMark().path(in: unit)
            let line: CGFloat = 12, gap: CGFloat = 21

            var overTLBR = Path()   // ovdje je O iznad X-a
            overTLBR.addRect(CGRect(x: 22, y: 22, width: 25, height: 25))
            overTLBR.addRect(CGRect(x: 53, y: 53, width: 25, height: 25))
            var overTRBL = Path()   // ovdje je X iznad O-a
            overTRBL.addRect(CGRect(x: 53, y: 22, width: 25, height: 25))
            overTRBL.addRect(CGRect(x: 22, y: 53, width: 25, height: 25))

            let cutO = cross.strokedPath(StrokeStyle(lineWidth: gap, lineCap: .round)).intersection(overTRBL)
            let cutX = ring.strokedPath(StrokeStyle(lineWidth: gap)).intersection(overTLBR)

            var o = ctx
            o.clip(to: cutO, options: .inverse)
            o.stroke(ring, with: .color(oColor), lineWidth: line)

            var x = ctx
            x.clip(to: cutX, options: .inverse)
            x.stroke(cross, with: .color(xColor), style: StrokeStyle(lineWidth: line, lineCap: .round))
        }
        .accessibilityLabel("XO Igrice")
    }
}

#Preview {
    XOLogo()
        .frame(width: 200, height: 200)
        .padding()
        .background(XOBrand.background)
}
