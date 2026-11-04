import SwiftUI

// MARK: - StepEquipmentRow
/// The equipment the rung needs ("Sprzęt"), with an optional tip.
struct StepEquipmentRow: View {
    let step: ProgressionStep

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sprzęt")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

            Text(ProgressionFormat.equipment(step.equipment))
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            if let tip = step.tip {
                Text("Wskazówka: \(tip)")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
