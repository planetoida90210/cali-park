import SwiftUI

// MARK: - ParkPhotosSectionView
struct ParkPhotosSectionView: View {

    @EnvironmentObject private var viewModel: ParkPhotosViewModel
    let isPremiumUser: Bool

    // Local UI state
    @State private var selectedPhoto: CommunityPhoto?
    @State private var showAddPhotoSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zdjęcia z parku")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

            HStack(spacing: 8) {
                if isPremiumUser {
                    AddPhotoCell {
                        showAddPhotoSheet = true
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.photos) { photo in
                            ParkPhotoThumbnail(photo: photo)
                                .onTapGesture { selectedPhoto = photo }
                        }
                    }
                }
                .frame(height: 80)
            }
            .overlay(premiumOverlay)
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            ParkPhotoGalleryView(selected: photo, photos: viewModel.photos, isPremiumUser: isPremiumUser)
        }
        .sheet(isPresented: $showAddPhotoSheet) {
            AddParkPhotoSheetView()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Premium Overlay
    @ViewBuilder private var premiumOverlay: some View {
        if !isPremiumUser {
            ZStack {
                Color.black.opacity(0.4).blur(radius: 0)
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white)
                    Text("Tylko w Premium")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Add Photo Cell
    private struct AddPhotoCell: View {
        let action: () -> Void
        var body: some View {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(uiColor: .secondarySystemBackground).opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accent, style: StrokeStyle(lineWidth: 2, dash: [4]))
                        )
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.accent)
                }
            }
        }
    }

    // MARK: - Thumbnail
    private struct ParkPhotoThumbnail: View {
        let photo: CommunityPhoto
        var body: some View {
            AsyncImage(url: photo.imageURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure(_):
                    Color.gray
                default:
                    ProgressView()
                }
            }
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: .secondarySystemBackground).opacity(0.2))
            )
        }
    }
}

// MARK: - Preview
#Preview {
    ParkPhotosSectionView(isPremiumUser: true)
        .environmentObject(ParkPhotosViewModel(parkID: Park.mock.first!.id))
        .padding()
        .preferredColorScheme(.dark)
} 