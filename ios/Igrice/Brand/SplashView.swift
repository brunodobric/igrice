import SwiftUI

/// Uvodna animacija (2 s): X dolazi slijeva, O zdesna, sudare se,
/// isprepletu u logo, logo se digne i ispod se pojavi ime.
/// Dodir je preskače. Uz Reduce Motion prikazuje samo logo i ime.
struct SplashView: View {
    /// Poziva se jednom, kad uvod treba nestati.
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var arrived = false      // X i O su doletjeli
    @State private var woven = false        // umjesto dva znaka prikazan je logo
    @State private var squash = false       // spljoštenje u sudaru
    @State private var burstStart = false   // cijan val se pojavi
    @State private var burstEnd = false     // val se raširi i nestane
    @State private var named = false        // logo gore, ime vidljivo
    @State private var finished = false

    private let logoSize: CGFloat = 150

    var body: some View {
        ZStack {
            XOBrand.background.ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(XOBrand.o, lineWidth: 3 * logoSize / 100)
                        .frame(width: logoSize * 0.6, height: logoSize * 0.6)
                        .scaleEffect(burstEnd ? 1.9 : 0.7)
                        .opacity(burstEnd ? 0 : (burstStart ? 0.8 : 0))

                    XMark()
                        .stroke(XOBrand.x, style: StrokeStyle(lineWidth: 12 * logoSize / 100, lineCap: .round))
                        .rotationEffect(.degrees(arrived ? 0 : -200))
                        .offset(x: arrived ? 0 : -260)
                        .opacity(arrived && !woven ? 1 : 0)

                    OMark()
                        .stroke(XOBrand.o, lineWidth: 12 * logoSize / 100)
                        .scaleEffect(arrived ? 1 : 0.55)
                        .offset(x: arrived ? 0 : 260)
                        .opacity(arrived && !woven ? 1 : 0)

                    XOLogo()
                        .opacity(woven ? 1 : 0)
                }
                .frame(width: logoSize, height: logoSize)
                .scaleEffect(x: squash ? 1.14 : 1, y: squash ? 0.9 : 1)
                .offset(y: named ? 0 : 36)

                HStack(spacing: 0) {
                    Text("X").foregroundStyle(XOBrand.x)
                    Text("O").foregroundStyle(XOBrand.o)
                    Text(" Igrice").foregroundStyle(XOBrand.text)
                }
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .opacity(named ? 1 : 0)
                .offset(y: named ? 0 : 10)
                .accessibilityElement(children: .combine)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .task { await play() }
    }

    private func play() async {
        if reduceMotion {
            woven = true
            named = true
            guard await pause(1.2) else { return }
            finish()
            return
        }

        // 0,00 s: ulazak
        withAnimation(.spring(duration: 0.55, bounce: 0.35)) { arrived = true }

        // 0,50 s: sudar
        guard await pause(0.5) else { return }
        burstStart = true
        withAnimation(.easeOut(duration: 0.45)) { burstEnd = true }
        withAnimation(.easeOut(duration: 0.1)) { squash = true }

        // 0,55 s: isprepletanje
        guard await pause(0.05) else { return }
        woven = true

        // 0,60 s: povratak iz spljoštenja
        guard await pause(0.05) else { return }
        withAnimation(.spring(duration: 0.3, bounce: 0.5)) { squash = false }

        // 0,95 s: logo se diže, ime ulazi
        guard await pause(0.35) else { return }
        withAnimation(.spring(duration: 0.45, bounce: 0)) { named = true }

        // 1,75 s: pretapanje u igru
        guard await pause(0.8) else { return }
        finish()
    }

    /// Čeka zadano vrijeme; vraća false ako je uvod u međuvremenu preskočen.
    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(seconds))
        return !Task.isCancelled && !finished
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        withAnimation(.easeIn(duration: 0.25)) { onFinish() }
    }
}

#Preview {
    SplashView { }
}
