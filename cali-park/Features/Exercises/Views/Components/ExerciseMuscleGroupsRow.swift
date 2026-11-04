import SwiftUI

// MARK: - ExerciseMuscleGroupsRow
struct ExerciseMuscleGroupsRow: View {
    let groups: [MuscleGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grupy mięśniowe")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                ForEach(groups) { group in
                    Text(group.displayName)
                        .font(.bodySmall)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color.componentBackground)
                        .foregroundStyle(Color.textPrimary)
                        .clipShape(.capsule)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
