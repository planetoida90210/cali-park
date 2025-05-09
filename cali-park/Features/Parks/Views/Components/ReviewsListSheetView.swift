import SwiftUI

// MARK: - ReviewsListSheetView
struct ReviewsListSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ParkReviewsViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.reviews) { review in
                    ReviewRowView(review: review)
                }
            }
            .navigationTitle("Opinie (\(viewModel.reviews.count))")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ReviewsListSheetView(viewModel: ParkReviewsViewModel(parkID: Park.mock.first!.id))
} 