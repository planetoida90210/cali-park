import SwiftUI

struct ParkCardView: View {
    @EnvironmentObject private var viewModel: ParksViewModel
    let park: Park

    var body: some View {
        HStack(spacing: 14) {
            // Placeholder image
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.25))
                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.textSecondary)
            }
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(park.name)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(park.city)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                if let distance = park.distance {
                    Text(String(format: "%.1f km", distance))
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            Spacer(minLength: 16)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.toggleFavorite(for: park)
                }
            }) {
                Image(systemName: park.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(park.isFavorite ? .accent : .textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
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
}

struct ParkCardView_Previews: PreviewProvider {
    static var previews: some View {
        ParkCardView(park: .mock.first!)
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 