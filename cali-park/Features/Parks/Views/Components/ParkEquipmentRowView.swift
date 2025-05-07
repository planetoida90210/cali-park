import SwiftUI

// MARK: - ParkEquipmentRowView
/// Jednolinijkowy pasek wyposażenia — 3 pierwsze ikony + badge "+n" (jeśli trzeba).
struct ParkEquipmentRowView: View {
    let equipments: [String]
    let onTapShowAll: () -> Void

    // Sprawdzone, istniejące SF Symbols
    private let iconMap: [String: String] = [
        "Pull-up bar": "figure.strengthtraining.traditional", // iOS 16+
        "Dip bar": "figure.flexibility", // fallback na figurę gimnastyczną
        "Monkey bars": "ladder",
        "Rings": "circle.grid.cross", // dostępny
        "Push-up handles": "hands.sparkles",
        "Climbing rope": "figure.climbing",
        "Box jump": "square.fill",
        "Resistance bands": "bolt",
        "Parallel bars": "rectangle.compress.vertical",
        "Tires": "circle", // placeholder
        "Battle ropes": "wave.3.forward",
        "Sledge hammer": "hammer",
        "Kettlebell": "dumbbell",
        "Medicine ball": "circle.inset.filled"
    ]

    // MARK: Body
    var body: some View {
        HStack(spacing: 20) {
            ForEach(displayedItems, id: \.self) { equipment in
                equipmentCell(for: equipment)
            }
            if overflowCount > 0 {
                overflowCell(count: overflowCount)
            }
        }
    }

    // Helpers
    private var displayedItems: [String] {
        Array(equipments.prefix(3))
    }

    private var overflowCount: Int {
        max(0, equipments.count - 3)
    }

    private func symbolName(for equipment: String) -> String {
        iconMap[equipment] ?? "questionmark"
    }

    // MARK: Cells
    @ViewBuilder
    private func equipmentCell(for equipment: String) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color.accent.opacity(0.9))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: symbolName(for: equipment))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                )
            Text(shortLabel(for: equipment))
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(minWidth: 52)
        .accessibilityElement()
        .accessibilityLabel(equipment)
        .onTapGesture { onTapShowAll() }
    }

    private func overflowCell(count: Int) -> some View {
        VStack(spacing: 4) {
            Circle()
                .strokeBorder(Color.textPrimary.opacity(0.3), lineWidth: 1)
                .background(Circle().fill(Color.componentBackground.opacity(0.2)))
                .frame(width: 44, height: 44)
                .overlay(
                    Text("+\(count)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.textPrimary)
                )
            Text("więcej")
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(minWidth: 52)
        .onTapGesture { onTapShowAll() }
    }

    private func shortLabel(for equipment: String) -> String {
        // Pierwsze słowo lub skrót – maks 8 znaków
        let label = equipment.split(separator: " ").first.map(String.init) ?? equipment
        return label.count > 8 ? String(label.prefix(8)) : label
    }
}

// MARK: - Preview
#Preview {
    ParkEquipmentRowView(
        equipments: [
            "Pull-up bar", "Dip bar", "Monkey bars", "Rings", "Push-up handles"
        ],
        onTapShowAll: {}
    )
    .padding()
    .preferredColorScheme(.dark)
} 