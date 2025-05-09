import SwiftUI

// MARK: - AddReviewSheetView
struct AddReviewSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ParkReviewsViewModel

    @State private var rating: Int
    @State private var comment: String

    // MARK: Init
    init(viewModel: ParkReviewsViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _rating = State(initialValue: viewModel.userReview?.rating ?? 3)
        _comment = State(initialValue: viewModel.userReview?.comment ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ocena") {
                    RatingStarsView(rating: $rating)
                        .padding(.vertical, 6)
                }
                Section("Komentarz (opcjonalnie)") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(comment.count)/140")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                                .padding(4)
                        }
                        .onChange(of: comment) { newValue in
                            if newValue.count > 140 { comment = String(newValue.prefix(140)) }
                        }
                }
            }
            .navigationTitle(viewModel.userReview == nil ? "Nowa opinia" : "Edytuj opinię")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") { Task { await save() } }
                        .disabled(rating < 1)
                }
            }
            .interactiveDismissDisabled(viewModel.isBusy)
            .overlay {
                if viewModel.isBusy {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Actions
    private func save() async {
        await viewModel.submit(rating: rating, comment: comment)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddReviewSheetView(viewModel: ParkReviewsViewModel(parkID: Park.mock.first!.id))
} 