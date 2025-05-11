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
    @FocusState private var commentFieldFocused: Bool

    init(selected: CommunityPhoto, photos: [CommunityPhoto], isPremiumUser: Bool) {
        self.selected = selected
        self.photos = photos
        self.isPremiumUser = isPremiumUser
        _currentIndex = State(initialValue: photos.firstIndex(of: selected) ?? 0)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                TabView(selection: $currentIndex) {
                    ForEach(photos.indices, id: \.self) { idx in
                        let photo = photos[idx]
                        PhotoDetailItem(photoID: photo.id,
                                       initialPhoto: photo,
                                       isOwner: photo.uploaderName == "Ty",
                                       onDeleteRequest: { showDeleteAlert = true },
                                       commentFocus: $commentFieldFocused)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicator (hidden while writing comment)
                if !commentFieldFocused {
                    pageIndicator
                        .padding(.bottom, 72)
                }
            }
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
            .onChange(of: currentIndex) { _ in commentFieldFocused = false }
        }
    }

    // MARK: Page Indicator
    private var pageIndicator: some View {
        let total = photos.count
        if total <= 8 {
            return AnyView(HStack(spacing: 6) {
                ForEach(0..<total, id: \..self) { idx in
                    Circle()
                        .fill(idx == currentIndex ? Color.accent : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            })
        } else {
            return AnyView(
                Text("\(currentIndex + 1)/\(total)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
            )
        }
    }
}

// MARK: - PhotoDetailItem
private struct PhotoDetailItem: View {
    let photoID: UUID
    let initialPhoto: CommunityPhoto // fallback for preview
    let isOwner: Bool
    let onDeleteRequest: () -> Void
    var commentFocus: FocusState<Bool>.Binding

    @EnvironmentObject private var vm: ParkPhotosViewModel
    @State private var scale: CGFloat = 1
    @State private var doubleTapAnim = false
    @State private var newComment: String = ""
    @State private var showActionSheet = false

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

                Text(photo.formattedDate)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { commentFocus.wrappedValue = false }
        .safeAreaInset(edge: .bottom) {
            commentInputBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appBackground)
        }
        .confirmationDialog("Opcje zdjęcia", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button(photo.visibility == .public ? "Ustaw jako prywatne" : "Ustaw jako publiczne") {
                vm.toggleVisibility(for: photo)
            }
            Button("Usuń", role: .destructive) { onDeleteRequest() }
            Button("Anuluj", role: .cancel) {}
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

            if photo.visibility == .friendsOnly {
                Image(systemName: "lock.fill")
                    .font(.caption)
            }

            Spacer()

            if isOwner {
                Button {
                    showActionSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 20) {
            Button(action: likeTapped) {
                Image(systemName: photo.isLikedByMe ? "heart.fill" : "heart")
            }

            Button(action: { commentFocus.wrappedValue = true }) {
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
                .focused(commentFocus)
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
        commentFocus.wrappedValue = false
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