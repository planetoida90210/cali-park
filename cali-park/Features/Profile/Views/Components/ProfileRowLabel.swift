import SwiftUI

// MARK: - ProfileRowLabel
/// A Profile list row's title with its accent icon.
struct ProfileRowLabel: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accent)
        }
    }
}
