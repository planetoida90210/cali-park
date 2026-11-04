import SwiftUI

// MARK: - StreakEmptyState
/// Shown before the first logged workout: no streak yet.
struct StreakEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame")
                .font(.appTitle2)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)

            Text("Brak serii")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zaloguj trening, aby zacząć.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
