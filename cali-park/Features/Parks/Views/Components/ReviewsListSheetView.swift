import SwiftUI

// MARK: - ReviewsListSheetView
struct ReviewsListSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ParkReviewsViewModel

    var body: some View {
        NavigationStack {
            List {
                // Filter toggle
                Toggle(isOn: $viewModel.showOnlyWithComment) {
                    Text("Tylko z komentarzem")
                }
                .toggleStyle(.switch)
                .font(.caption)

                ForEach(viewModel.loadedReviews) { review in
                    ReviewRowView(review: review)
                }

                if viewModel.hasMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .onAppear { viewModel.loadMore() }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Opinie (\(viewModel.filteredReviews.count))")
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