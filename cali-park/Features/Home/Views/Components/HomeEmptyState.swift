import SwiftUI

// MARK: - HomeEmptyState
/// What Home shows when no module is enabled: a short note and a button that
/// opens the module selection.
struct HomeEmptyState: View {
    /// Opens the module selection sheet.
    let onAddModules: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.appLargeTitle)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            Text("Start jest pusty")
                .font(.appTitle3)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Dodaj moduły, aby zobaczyć tu potrzebne informacje")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Dodaj moduły") {
                onAddModules()
            }
            .buttonStyle(.accent(.compact, fillsWidth: false))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 16)
    }
}
