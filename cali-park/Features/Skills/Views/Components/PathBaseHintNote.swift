import SwiftUI

// MARK: - PathBaseHintNote
/// A neutral, non-binding note about movements people usually build this path
/// on. Never a prerequisite.
struct PathBaseHintNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.textSecondary)
            Text(text)
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: AppRadius.medium))
    }
}
