import SwiftUI

/// Prekidač s više opcija u izgledu iz dizajna (Razina, Tema).
struct SegmentedControl<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let active = option.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = option.value }
                } label: {
                    Text(option.label)
                        .font(.system(size: 15, weight: active ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(active ? Theme.text : Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if active {
                                Capsule()
                                    .fill(Theme.surfaceRaised)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.cell))
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }
}
