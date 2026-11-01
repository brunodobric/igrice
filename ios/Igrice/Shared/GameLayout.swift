import SwiftUI

/// Raspored ekrana igre: ploča, rezultati i gumbi.
///
/// Na iOS 27.1 i novijem koristi sistemski `ArrangementView` (split). Na iPhone Duu
/// tako ploča i kontrole uvijek ostaju na različitim stranama pregiba kad je uređaj
/// napola presavijen: kao laptop ploča je gore, a kontrole dolje; kao knjiga stoje
/// jedno pored drugoga. Na neprevijenom zaslonu u portretu ploča je gore, a rezultati
/// i gumbi ispod nje. Kontrole dobivaju svoju prirodnu visinu, a ploča ostatak.
///
/// Na starijim sustavima ostaje dosadašnji okomiti raspored: rezultati, ploča, gumbi.
///
/// `ArrangementView` postoji tek u SDK-u za iOS 27.1 (Xcode 27.1, Swift 6.4). Provjera
/// `compiler` omogućuje da se projekt i dalje prevodi u starijem Xcodeu. Xcode 27.0
/// također ima Swift 6.4, ali nema taj SDK, pa za ovaj projekt treba Xcode 27.1 ili noviji.
struct GameLayout<Scores: View, Board: View, Actions: View>: View {
    private let scores: Scores
    private let board: Board
    private let actions: Actions

    private let spacing: CGFloat = 16

    init(@ViewBuilder scores: () -> Scores,
         @ViewBuilder board: () -> Board,
         @ViewBuilder actions: () -> Actions) {
        self.scores = scores()
        self.board = board()
        self.actions = actions()
    }

    var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            arranged
        } else {
            stacked
        }
        #else
        stacked
        #endif
    }

    /// Dosadašnji raspored, za iOS 17 do 27.0.
    private var stacked: some View {
        VStack(spacing: spacing) {
            scores
            board
            actions
        }
        .padding(spacing)
    }

    #if compiler(>=6.4)
    /// Primarni dio je ploča, sekundarni rezultati i gumbi. Aplikacija je zaključana u
    /// portretu, pa se ne događa slučaj u kojem split prikazuje samo primarni dio
    /// (zatvoren iPhone Duo u vodoravnom položaju).
    @available(iOS 27.1, *)
    private var arranged: some View {
        ArrangementView {
            board
                .padding(spacing)
                .layoutPriority(1)
        } secondary: {
            VStack(spacing: spacing) {
                scores
                actions
            }
            // bez gornjeg ruba: razmak do ploče daje njezin donji rub
            .padding([.horizontal, .bottom], spacing)
            .splitArrangementFixedLayoutSize(horizontal: false, vertical: true)
        }
        .arrangementViewStyle(.split)
    }
    #endif
}
