import SwiftUI

// MARK: - NextWorkoutEmptyState
/// No plans and nothing to suggest yet.
struct NextWorkoutEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.appTitle2)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)

            Text("Brak propozycji")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zaloguj pierwszy trening lub zaplanuj kolejny.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
