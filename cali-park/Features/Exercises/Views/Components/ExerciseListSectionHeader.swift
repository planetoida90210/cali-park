import SwiftUI

// MARK: - ExerciseListSectionHeader
/// "Ulubione" / "Wszystkie ćwiczenia" above a block of exercise rows.
struct ExerciseListSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.bodySmall)
            .foregroundStyle(Color.textSecondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }
}
