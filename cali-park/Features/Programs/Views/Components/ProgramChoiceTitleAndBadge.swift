import SwiftUI

// MARK: - ProgramChoiceTitleAndBadge
/// A program choice's name and, when suggested, the "Polecany" badge. Two
/// sibling views, so the caller's stack decides whether they sit in a row
/// or a column.
struct ProgramChoiceTitleAndBadge: View {
    let title: String
    let isSuggested: Bool

    var body: some View {
        Text(title)
            .font(.bodyLarge)
            .foregroundStyle(Color.textPrimary)
        if isSuggested {
            Text("Polecany")
                .font(.buttonSmall)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.accent, in: .capsule)
        }
    }
}
