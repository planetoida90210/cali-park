import SwiftUI

// MARK: - ExerciseEquipmentRow
struct ExerciseEquipmentRow: View {
    let equipment: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sprzęt")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

            Text(ProgressionFormat.equipment(equipment))
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
