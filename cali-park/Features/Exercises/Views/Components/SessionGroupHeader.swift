import SwiftUI

// MARK: - SessionGroupHeader
/// "Para 1" or "Obwód" above a group, with how it is done.
struct SessionGroupHeader: View {
    let group: QuickWorkoutViewModel.SessionGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(group.title)
                .font(.bodyLarge.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let instruction = group.instruction {
                Text(instruction)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }
}
