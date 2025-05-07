import SwiftUI

// MARK: - EquipmentSheetView
/// Prosty arkusz z listą pełnego wyposażenia parku.
struct EquipmentSheetView: View {
    // MARK: Properties
    let equipments: [String]
    @Environment(\.dismiss) private var dismiss

    // MARK: Body
    var body: some View {
        NavigationStack {
            List {
                if equipments.isEmpty {
                    Text("Brak danych")
                        .foregroundColor(.textSecondary)
                } else {
                    ForEach(equipments.sorted(), id: \.self) { item in
                        HStack(spacing: 12) {
                            Image(systemName: symbolName(for: item))
                                .frame(width: 20)
                                .foregroundColor(.accent)
                            Text(item)
                                .foregroundColor(.textPrimary)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
                    }
                }
            }
            .navigationTitle("Wyposażenie")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
        }
    }

    // MARK: Helpers
    private func symbolName(for equipment: String) -> String {
        // Proste mapowanie – zsynchronizowane z ParkEquipmentChipsView
        let mapping: [String: String] = [
            "Pull-up bar": "figure.pullup",
            "Dip bar": "flame",
            "Monkey bars": "rectangle.3.offgrid",
            "Rings": "circle.grid.cross",
            "Push-up handles": "hands.sparkles"
        ]
        return mapping[equipment] ?? "questionmark"
    }
}

// MARK: - Preview
#Preview {
    EquipmentSheetView(equipments: ["Pull-up bar", "Dip bar", "Monkey bars", "Rings"])
        .preferredColorScheme(.dark)
} 