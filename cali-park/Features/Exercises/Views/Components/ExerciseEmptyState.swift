import SwiftUI

// MARK: - ExerciseEmptyState
struct ExerciseEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.appTitle2)
                .foregroundStyle(Color.accent.opacity(0.8))

            Text("Brak wyników")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zmień kategorię lub wpisz inną nazwę.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
