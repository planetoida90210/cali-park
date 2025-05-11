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
                    AsyncImage(url: photo.imageURL) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFit()
                        case .failure(_):
                            Color.gray
                        default:
                            ProgressView()
                        }
                    }
                    .tag(idx)
                    .ignoresSafeArea()
                    .onLongPressGesture(minimumDuration: 0.6) {
                        if isPremiumUser { showDeleteAlert = true }
                    }
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

// MARK: - Preview
#Preview {
    ParkPhotoGalleryView(selected: CommunityPhoto.photos(for: Park.mock.first!.id).first!,
                         photos: CommunityPhoto.photos(for: Park.mock.first!.id),
                         isPremiumUser: true)
        .environmentObject(ParkPhotosViewModel(parkID: Park.mock.first!.id))
        .preferredColorScheme(.dark)
} 