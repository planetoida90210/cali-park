import SwiftUI

// MARK: - ProgramsEntryRow
/// The way into "Gotowe programy" above the plan list.
struct ProgramsEntryRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.appTitle3)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Gotowe programy")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                Text("Minimum, Fundamenty, Pierwsze podciągnięcie, Skille")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.bodySmall)
                .foregroundStyle(Color.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
