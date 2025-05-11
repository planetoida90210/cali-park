import SwiftUI

// MARK: - ParkPhotoGalleryView
struct ParkPhotoGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var photosVM: ParkPhotosViewModel

    let selected: CommunityPhoto
    let photos: [CommunityPhoto]
    let isPremiumUser: Bool

    @State private var currentIndex: Int
    @State private var showDeleteAlert = false

    init(selected: CommunityPhoto, photos: [CommunityPhoto], isPremiumUser: Bool) {
        self.selected = selected
        self.photos = photos
        self.isPremiumUser = isPremiumUser
        _currentIndex = State(initialValue: photos.firstIndex(of: selected) ?? 0)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { idx in
                    let photo = photos[idx]
                    PhotoDetailItem(photoID: photo.id, initialPhoto: photo, isOwner: photo.uploaderName == "Ty", onDeleteRequest: { showDeleteAlert = true })
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .navigationTitle(photos[currentIndex].uploaderName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
            .alert("Usuń zdjęcie?", isPresented: $showDeleteAlert) {
                Button("Usuń", role: .destructive) {
                    let photo = photos[currentIndex]
                    photosVM.delete(photo)
                    if photosVM.photos.isEmpty { dismiss() }
                }
                Button("Anuluj", role: .cancel) {}
            }
        }
    }
}

// MARK: - PhotoDetailItem
private struct PhotoDetailItem: View {
    let photoID: UUID
    let initialPhoto: CommunityPhoto // fallback for preview
    let isOwner: Bool
    let onDeleteRequest: () -> Void

    @EnvironmentObject private var vm: ParkPhotosViewModel
    @State private var scale: CGFloat = 1
    @State private var doubleTapAnim = false
    @State private var newComment: String = ""
    @FocusState private var commentFieldFocused: Bool

    private var photo: CommunityPhoto {
        vm.photos.first(where: { $0.id == photoID }) ?? initialPhoto
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header

                // Image with gestures
                ZStack {
                    GeometryReader { geo in
                        AsyncImage(url: photo.imageURL) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.width)
                                    .clipped()
                            case .failure(_):
                                Color.gray
                            default:
                                ProgressView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(magnificationGesture)
                    .highPriorityGesture(doubleTapGesture)
                    .onLongPressGesture(minimumDuration: 0.6) { if isOwner { onDeleteRequest() } }

                    if doubleTapAnim {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.white.opacity(0.9))
                            .scaleEffect(doubleTapAnim ? 1 : 0.4)
                            .animation(.easeOut(duration: 0.5), value: doubleTapAnim)
                    }
                }

                actionBar

                Text("Liczba polubień: \(photo.likes)")
                    .font(.bodyMedium)

                if !photo.caption.isEmpty {
                    Text("\(photo.uploaderName) \(photo.caption)")
                        .font(.bodySmall)
                }

                // Recent comments (show last 2)
                if let list = vm.comments[photo.id], !list.isEmpty {
                    ForEach(list.suffix(2)) { c in
                        HStack {
                            Text(c.authorName).font(.bodyMedium)
                            Text(c.text).font(.bodySmall)
                            Spacer()
                        }
                    }
                }

                commentInputBar

                Text(photo.formattedDate)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: Subviews
    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accent)
                .frame(width: 36, height: 36)
                .overlay(Text(String(photo.uploaderName.prefix(1))).foregroundColor(.black))

            Text(photo.uploaderName)
                .font(.bodyMedium)

            Spacer()

            if isOwner {
                Button(role: .destructive) { onDeleteRequest() } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 20) {
            Button(action: likeTapped) {
                Image(systemName: photo.isLikedByMe ? "heart.fill" : "heart")
            }

            Button(action: { commentFieldFocused = true }) {
                Image(systemName: "bubble.right")
            }

            ShareLink(item: photo.imageURL) {
                Image(systemName: "paperplane")
                    .rotationEffect(.degrees(-45))
            }
        }
        .font(.title3)
        .foregroundColor(.textPrimary)
    }

    // MARK: Gestures
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1, min(value, 4))
                if scale > 1.1 { /* nothing */ }
            }
            .onEnded { _ in
                withAnimation(.spring()) {
                    scale = 1
                }
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                likeTapped()
                withAnimation { doubleTapAnim = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { doubleTapAnim = false }
            }
    }

    private func likeTapped() {
        vm.toggleLike(for: photo)
    }

    // Input bar
    private var commentInputBar: some View {
        HStack {
            TextField("Dodaj komentarz…", text: $newComment)
                .focused($commentFieldFocused)
                .textFieldStyle(.roundedBorder)

            Button(action: sendComment) {
                Image(systemName: "paperplane.fill")
                    .rotationEffect(.degrees(45))
            }
            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func sendComment() {
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        vm.addComment(to: photo.id, text: trimmed)
        newComment = ""
    }
}

// MARK: - Preview
#Preview {
    ParkPhotoGalleryView(selected: CommunityPhoto.photos(for: Park.mock.first!.id).first!,
                         photos: CommunityPhoto.photos(for: Park.mock.first!.id),
                         isPremiumUser: true)
        .environmentObject(ParkPhotosViewModel(parkID: Park.mock.first!.id))
        .preferredColorScheme(.dark)
} 