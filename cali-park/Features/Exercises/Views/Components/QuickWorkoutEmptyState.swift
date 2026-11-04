import SwiftUI

// MARK: - QuickWorkoutEmptyState
struct QuickWorkoutEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.appLargeTitle)
                .foregroundStyle(Color.accent)

            Text("Zbuduj trening")
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Dodaj dowolne ćwiczenia i zapisz je jako jeden trening.")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Dodaj ćwiczenie", systemImage: "plus", action: onAdd)
                .buttonStyle(.accent(.compact, fillsWidth: false))
                .accessibilityIdentifier("quickWorkout.addExercise")
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
