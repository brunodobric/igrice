import SwiftUI

/// Ishod igre za sistemski alert.
struct GameResult: Equatable {
    let title: String
    let message: String
}

private struct GameResultAlert: ViewModifier {
    @Binding var result: GameResult?
    let buttonTitle: String
    let action: () -> Void

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            // kratka stanka da se vidi završna ploča prije alerta
            .task(id: result) {
                guard result != nil else { isPresented = false; return }
                try? await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled { isPresented = true }
            }
            .alert(result?.title ?? "", isPresented: $isPresented, presenting: result) { _ in
                Button(buttonTitle) {
                    result = nil
                    action()
                }
            } message: { result in
                Text(result.message)
            }
    }
}

extension View {
    /// Pokazuje alert s ishodom pola sekunde nakon što `result` dobije vrijednost.
    /// Gumb briše ishod i poziva `action` (nova igra).
    func gameResultAlert(_ result: Binding<GameResult?>, buttonTitle: String,
                         action: @escaping () -> Void) -> some View {
        modifier(GameResultAlert(result: result, buttonTitle: buttonTitle, action: action))
    }
}
