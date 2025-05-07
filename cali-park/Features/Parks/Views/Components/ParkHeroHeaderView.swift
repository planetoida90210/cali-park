import SwiftUI

// MARK: - ParkHeroHeaderView
/// A full–width parallax gallery header with rating & media badges.
struct ParkHeroHeaderView: View {
    let park: Park
    let isPremiumUser: Bool

    @State private var currentIndex: Int = 0
    @EnvironmentObject private var parksVM: ParksViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $currentIndex) {
                    headerImages(geo: geo)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))

                badges
            }
            // Parallax effect – scale & offset when pulling down
            .frame(height: headerHeight(geo))
            .clipped()
            .offset(y: -parallaxOffset(geo))
        }
        .frame(height: 260) // Base height
    }

    // MARK: - Image Carousel
    @ViewBuilder
    private func headerImages(geo: GeometryProxy) -> some View {
        if park.images.isEmpty {
            // Placeholder when no images
            Color.componentBackground
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary)
                        Text("Brak zdjęć")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                )
                .tag(0)
        } else {
            ForEach(Array(park.images.enumerated()), id: \.offset) { index, url in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width,
                                   height: geo.size.height + parallaxOffset(geo))
                            .clipped()
                            .offset(y: -parallaxOffset(geo))
                    case .empty:
                        Color.black.opacity(0.05)
                    default:
                        Color.gray.opacity(0.2)
                    }
                }
                .tag(index)
            }
        }
    }

    // MARK: - Badges Overlay
    private var badges: some View {
        HStack(spacing: 8) {
            // Rating
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.accent)
                Text(String(format: "%.1f", park.rating))
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            // Favorite toggle
            Button(action: toggleFavorite) {
                Image(systemName: currentFavorite ? "heart.fill" : "heart")
                    .font(.caption.weight(.bold))
                    .foregroundColor(currentFavorite ? .accent : .white)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Images count
            if park.images.count > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                    Text("\(park.images.count)")
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .padding(12)
    }

    // MARK: - Helpers
    private func parallaxOffset(_ geo: GeometryProxy) -> CGFloat {
        let y = geo.frame(in: .global).minY
        return y > 0 ? y : 0
    }

    private func headerHeight(_ geo: GeometryProxy) -> CGFloat {
        let base: CGFloat = 260
        let extra = parallaxOffset(geo)
        return base + extra
    }

    private var currentFavorite: Bool {
        parksVM.parks.first(where: { $0.id == park.id })?.isFavorite ?? park.isFavorite
    }

    private func toggleFavorite() {
        parksVM.toggleFavorite(for: park)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        ParkHeroHeaderView(park: .mock.first!, isPremiumUser: false)
            .environmentObject(ParksViewModel())
    }
    .preferredColorScheme(.dark)
} 