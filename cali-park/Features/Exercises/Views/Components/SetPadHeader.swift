import SwiftUI

// MARK: - SetPadHeader
struct SetPadHeader<Accessory: View>: View {
    let exercise: Exercise
    /// Trailing control, e.g. the sheet's "Anuluj".
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .row)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.appTitle3)
                    .foregroundStyle(Color.textPrimary)

                if exercise.measurement == .seconds {
                    Text("Liczysz sekundy utrzymania")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            accessory
        }
    }
}
