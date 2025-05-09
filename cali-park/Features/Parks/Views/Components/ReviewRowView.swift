import SwiftUI

// MARK: - ReviewRowView
struct ReviewRowView: View {
    let review: ParkReview

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(authorName)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                Spacer()
                RatingStarsView(value: review.rating)
            }
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(dateString)
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(.vertical, 8)
    }

    private var authorName: String {
        // In UI-first phase we don't have full user lookup – fallback to anon.
        // Later we will map userID → User.
        "Użytkownik".appending(String(review.userID.uuidString.prefix(4)))
    }

    private var dateString: String {
        let df = Self.dateFormatter
        return df.string(from: review.updatedAt ?? review.createdAt)
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.dateStyle = .medium
        return df
    }()
}

// MARK: - Preview
#Preview {
    ReviewRowView(review: ParkReview.mocks(for: Park.mock.first!.id)[0])
        .padding()
        .preferredColorScheme(.dark)
} 