import SwiftUI

struct ParkReviewsSectionView: View {
    @ObservedObject var viewModel: ParkReviewsViewModel
    var onAddEdit: () -> Void = {}
    var onShowAll: () -> Void = {}
    @State private var isExpanded: Bool = true
    @State private var showAll: Bool = false
    private let recentLimit = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleRow
            if isExpanded {
                actionsRow
                Divider().opacity(0.4)
                reviewList
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut, value: isExpanded)
    }

    // MARK: - Title Row
    private var titleRow: some View {
        HStack(spacing: 6) {
            Text("Opinie")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundColor(.textSecondary)
            Spacer()
            if isExpanded && showAll && viewModel.loadedReviews.count > recentLimit {
                Button(action: { showAll = false }) {
                    Text("Zwiń")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { isExpanded.toggle() } }
    }

    // MARK: - Actions Row (bez gwiazdek)
    private var actionsRow: some View {
        HStack(spacing: 12) {
            Spacer()
            Button(action: onAddEdit) {
                Label(viewModel.userReview == nil ? "Dodaj" : "Edytuj", systemImage: viewModel.userReview == nil ? "plus" : "pencil")
            }
            .font(.caption)
            .buttonStyle(.bordered)

            Button(action: onShowAll) {
                Text("Wszystkie")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
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
            let reviewsToShow = showAll ? viewModel.loadedReviews : Array(viewModel.loadedReviews.prefix(recentLimit))
            ForEach(reviewsToShow) { review in
                ReviewRowView(review: review)
                if review.id != reviewsToShow.last?.id {
                    Divider().opacity(0.1)
                }
            }
            if !showAll && viewModel.hasMore {
                Button {
                    viewModel.loadMore()
                    showAll = true
                } label: {
                    Text("Więcej...")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.accent)
                }
                .padding(.top, 4)
            } else if showAll && viewModel.loadedReviews.count > recentLimit {
                Button {
                    showAll = false
                } label: {
                    Text("Zwiń")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.accent)
                }
                .padding(.top, 4)
            }
        }
    }
}

struct ParkReviewsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ParkReviewsSectionView()
    }
} 