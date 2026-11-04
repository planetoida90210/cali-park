import SwiftUI

// MARK: - WorkoutPlansEmptyState
/// Shown when there are no plans yet: create one or pick a ready-made program.
struct WorkoutPlansEmptyState: View {
    let onCreate: () -> Void
    let onBrowsePrograms: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.appLargeTitle)
                .foregroundStyle(Color.accent)

            Text("Zaplanuj trening")
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Zbuduj plan z ulubionych ćwiczeń i ustaw, jak często chcesz go trenować.")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Nowy plan", systemImage: "plus", action: onCreate)
                .buttonStyle(.accent(.compact, fillsWidth: false))
            .padding(.top, 8)

            Button("Wybierz gotowy program", systemImage: "list.bullet.clipboard", action: onBrowsePrograms)
                .font(.buttonMedium)
                .foregroundStyle(Color.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
