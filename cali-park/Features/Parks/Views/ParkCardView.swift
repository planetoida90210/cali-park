import SwiftUI

struct ParkCardView: View {
    let park: Park

    var body: some View {
        HStack(spacing: 12) {
            // Placeholder image
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .overlay(
                    Text("📷")
                        .font(.title)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(park.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(park.city)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                if let distance = park.distance {
                    Text(String(format: "%.1f km", distance))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            Spacer()
            if park.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.accent)
            }
        }
        .padding(12)
        .background(Color.glassBackground)
        .cornerRadius(14)
    }
}

struct ParkCardView_Previews: PreviewProvider {
    static var previews: some View {
        ParkCardView(park: .mock.first!)
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 