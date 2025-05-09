import SwiftUI

// MARK: - ParkReviewsSectionView
struct ParkReviewsSectionView: View {
    @ObservedObject var viewModel: ParkReviewsViewModel
    /// Callback used by parent to open add/edit sheet.
    var onAddEdit: () -> Void
    /// Callback used to show full list.
    var onShowAll: () -> Void

    private let recentLimit = 3
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if isExpanded {
                Divider().opacity(0.4)
                reviewList
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut, value: isExpanded)
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Opinie")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
                .onTapGesture { withAnimation { isExpanded.toggle() } }
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundColor(.textSecondary)
                .onTapGesture { withAnimation { isExpanded.toggle() } }

            Spacer(minLength: 16)

            RatingSummaryView(avg: viewModel.averageRating, count: viewModel.reviews.count)

            Spacer()

            Button(action: onAddEdit) {
                Label(viewModel.userReview == nil ? "Dodaj" : "Edytuj", systemImage: viewModel.userReview == nil ? "plus" : "pencil")
            }
            .font(.caption)
            .buttonStyle(.bordered) // neutral border, no fill

            Button(action: onShowAll) {
                Text("Wszystkie")
                    .foregroundColor(.textSecondary)
            }
            .font(.caption)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Review list (collapsed/expanded)
    @ViewBuilder
    private var reviewList: some View {
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