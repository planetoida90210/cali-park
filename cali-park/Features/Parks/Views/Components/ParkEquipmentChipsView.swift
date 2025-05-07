import SwiftUI

// MARK: - ParkEquipmentChipsView
/// Wyświetla maksymalnie 3 ikonki wyposażenia w formie "chips" + badge `+n` (jeśli jest więcej).
/// Tapnięcie dowolnego elementu wywołuje przekazaną akcję – zwykle otwarcie sheet-a z pełną listą.
struct ParkEquipmentChipsView: View {
    // MARK: Properties
    let equipments: [String]
    let onTapShowAll: () -> Void

    // Ikony SF Symbol przypisane do znanych sprzętów.
    private let iconMap: [String: String] = [
        "Pull-up bar": "figure.pullup",
        "Dip bar": "flame",
        "Monkey bars": "rectangle.3.offgrid",
        "Rings": "circle.grid.cross",
        "Push-up handles": "hands.sparkles"
    ]

    // MARK: Body
    var body: some View {
        HStack(spacing: 12) {
            ForEach(chipsToShow, id: \.self) { equipment in
                equipmentChip(for: equipment)
            }
            if overflowCount > 0 {
                overflowChip(count: overflowCount)
            }
        }
    }

    // MARK: Helpers
    private var chipsToShow: [String] {
        Array(equipments.prefix(3))
    }

    private var overflowCount: Int {
        max(0, equipments.count - 3)
    }

    private func symbolName(for equipment: String) -> String {
        iconMap[equipment] ?? "questionmark"
    }

    @ViewBuilder
    private func equipmentChip(for equipment: String) -> some View {
        let symbol = symbolName(for: equipment)
        ChipBase { Image(systemName: symbol) }
            .accessibilityLabel(Text(equipment))
            .onTapGesture { animatedTap() }
    }

    private func overflowChip(count: Int) -> some View {
        ChipBase { Text("+\(count)") }
            .onTapGesture { animatedTap() }
    }

    // Wraps content in a circular chip with shared styling.
    private func ChipBase<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(.caption)
            .foregroundColor(.textPrimary)
            .frame(width: 32, height: 32)
            .background(Color.textPrimary.opacity(0.15))
            .clipShape(Circle())
    }

    // Simple micro-interaction – scale animation + haptic.
    private func animatedTap() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            onTapShowAll()
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading) {
        ParkEquipmentChipsView(
            equipments: ["Pull-up bar", "Dip bar", "Monkey bars", "Rings"],
            onTapShowAll: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
} 