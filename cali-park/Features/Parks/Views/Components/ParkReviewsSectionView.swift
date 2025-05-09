import SwiftUI

// MARK: - ParkReviewsSectionView
struct ParkReviewsSectionView: View {
    @ObservedObject var viewModel: ParkReviewsViewModel
    /// Callback used by parent to open add/edit sheet.
    var onAddEdit: () -> Void
    /// Callback used to show full list.
    var onShowAll: () -> Void

    private let recentLimit = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider().opacity(0.4)
            // Recent reviews
            if viewModel.reviews.isEmpty {
                Text("Brak opinii")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            } else {
                ForEach(viewModel.reviews.prefix(recentLimit)) { review in
                    ReviewRowView(review: review)
                    if review.id != viewModel.reviews.prefix(recentLimit).last?.id {
                        Divider().opacity(0.1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center) {
            RatingSummaryView(avg: viewModel.averageRating, count: viewModel.reviews.count)
            Spacer()
            Button(action: onAddEdit) {
                Text(viewModel.userReview == nil ? "Dodaj" : "Edytuj")
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.borderedProminent)
            .tint(.accent)
            Button(action: onShowAll) {
                Text("Wszystkie")
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - RatingSummaryView
private struct RatingSummaryView: View {
    let avg: Double
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            RatingStarsView(value: Int(round(avg)))
            Text(String(format: "%.1f", avg))
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview
#Preview {
    let vm = ParkReviewsViewModel(parkID: Park.mock.first!.id)
    return VStack(alignment: .leading, spacing: 16) {
        ParkReviewsSectionView(viewModel: vm, onAddEdit: {}, onShowAll: {})
            .padding()
    }
    .preferredColorScheme(.dark)
} 