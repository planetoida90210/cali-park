import SwiftUI

// MARK: - AvatarStackView
/// Displays up to 3 circular avatars with an optional "+X" overflow indicator.
struct AvatarStackView: View {
    let participants: [User]
    let maxVisible: Int
    let size: CGFloat

    init(participants: [User], maxVisible: Int = 3, size: CGFloat = 24) {
        self.participants = participants
        self.maxVisible = maxVisible
        self.size = size
    }

    private var visible: [User] {
        Array(participants.prefix(maxVisible))
    }

    private var overflow: Int {
        max(0, participants.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(visible) { user in
                avatar(for: user)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.caption2.weight(.semibold))
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color.componentBackground))
                    .foregroundColor(.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func avatar(for user: User) -> some View {
        // Placeholder local circle, network loading later.
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text(initials(of: user.name))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
            )
            .frame(width: size, height: size)
    }

    private func initials(of name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }
}

#Preview {
    AvatarStackView(participants: Array(repeating: .mock, count: 5))
        .padding()
        .preferredColorScheme(.dark)
} 