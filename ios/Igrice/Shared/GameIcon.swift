import SwiftUI

/// Ikone igara iz donje trake (mreža 24 × 24, kao SVG u index.html).
struct GameIcon: View {
    let game: Game
    var color: Color = Theme.text
    var lineWidth: CGFloat = 2

    var body: some View {
        GameIconShape(game: game)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

private struct GameIconShape: Shape {
    let game: Game

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * s, y: rect.minY + y * s, width: w * s, height: h * s)
        }

        var path = Path()
        switch game {
        case .ticTacToe:
            path.move(to: p(4, 4)); path.addLine(to: p(10.5, 10.5))
            path.move(to: p(10.5, 4)); path.addLine(to: p(4, 10.5))
            path.addEllipse(in: box(13.2, 13.2, 7.2, 7.2))
        case .tango:
            path.addRoundedRect(in: box(2, 6, 20, 12), cornerSize: CGSize(width: 6 * s, height: 6 * s))
            path.move(to: p(6.6, 10)); path.addLine(to: p(10.6, 14))
            path.move(to: p(10.6, 10)); path.addLine(to: p(6.6, 14))
            path.addEllipse(in: box(13.7, 9.7, 4.6, 4.6))
        case .minesweeper:
            path.addRoundedRect(in: box(3.5, 3.5, 17, 17), cornerSize: CGSize(width: 5 * s, height: 5 * s))
            path.move(to: p(9, 9)); path.addLine(to: p(15, 15))
            path.move(to: p(15, 9)); path.addLine(to: p(9, 15))
        case .skyscrapers:
            path.move(to: p(6, 20)); path.addLine(to: p(6, 15))
            path.move(to: p(12, 20)); path.addLine(to: p(12, 10))
            path.move(to: p(18, 20)); path.addLine(to: p(18, 5))
        }
        return path
    }
}
