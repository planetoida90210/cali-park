import SwiftUI

struct ParkCardView: View {
    @EnvironmentObject private var viewModel: ParksViewModel
    let park: Park

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                headerRow
                locationRow
                equipmentsRow
            }
            Spacer(minLength: 8)

            likeButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.componentBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cardBorderEnd.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }

    // MARK: - Subviews

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.25))

            if let url = park.images.first {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        placeholderIcon
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderIcon
                    }
                }
                .clipped()
                .cornerRadius(10)
            } else {
                placeholderIcon
            }
        }
        .frame(width: 82, height: 82)
    }

    private var placeholderIcon: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 28))
            .foregroundColor(.textSecondary)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(park.name)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.accent)
                Text(String(format: "%.1f", park.rating))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var locationRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption)
                .foregroundColor(.textTertiary)

            Text(park.city)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)

            if let distance = park.distance {
                Text(String(format: "• %.1f km", distance))
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
    }

    private var equipmentsRow: some View {
        HStack(spacing: 6) {
            ForEach(park.equipments.prefix(3), id: \ .self) { eq in
                Text(eq)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.glassBackground)
                    )
            }
        }
    }

    private var likeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                viewModel.toggleFavorite(for: park)
            }
        }) {
            Image(systemName: park.isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(park.isFavorite ? .accent : .textSecondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ParkCardView_Previews: PreviewProvider {
    static var previews: some View {
        ParkCardView(park: .mock.first!)
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 