import SwiftUI

// MARK: - PhotoCommentsSheetView
struct PhotoCommentsSheetView: View {
    let photo: CommunityPhoto
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: ParkPhotosViewModel

    @State private var newComment: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                commentsList
                inputBar
            }
            .navigationTitle("Komentarze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } }
            }
        }
    }

    // MARK: Components
    private var commentsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(vm.comments[photo.id] ?? []) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(comment.authorName).font(.bodyMedium)
                            Spacer()
                            Text(comment.relativeDate).font(.caption).foregroundColor(.textSecondary)
                        }
                        Text(comment.text).font(.bodySmall)
                    }
                    .padding(.horizontal)
                }
                if (vm.comments[photo.id] ?? []).isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary)
                        Text("Brak komentarzy. Bądź pierwszy!")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 60)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack {
            TextField("Dodaj komentarz…", text: $newComment, axis: .vertical)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.componentBackground))

            Button(action: sendComment) {
                Image(systemName: "paperplane.fill")
                    .rotationEffect(.degrees(45))
                    .font(.title3)
            }
            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.appBackground)
    }

    // MARK: Actions
    private func sendComment() {
        let text = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        vm.addComment(to: photo.id, text: text)
        newComment = ""
    }
}

// MARK: - Preview
#Preview {
    PhotoCommentsSheetView(photo: CommunityPhoto.mock.first!)
        .environmentObject(ParkPhotosViewModel(parkID: CommunityPhoto.mock.first!.parkID))
        .preferredColorScheme(.dark)
} 