import SwiftUI
import CoreLocation

// MARK: - ParkStatsStripView
/// Compact strip with key park stats: address, distance and occupancy.
struct ParkStatsStripView: View {
    let park: Park

    // Dummy occupancy – in real app this will come from API/ML heuristics
    private var occupancyLevel: String {
        // Simple heuristic: random for now
        ["niski", "średni", "wysoki"].randomElement()!
    }

    private var distanceString: String {
        if let km = park.distance {
            return String(format: "%.1f km", km)
        } else {
            return "—"
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            stat(icon: "mappin.and.ellipse", text: park.city)
            stat(icon: "location.fill", text: distanceString)
            stat(icon: "person.3.sequence", text: "Tłok: \(occupancyLevel)")
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stat(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accent)
            Text(text)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    ParkStatsStripView(park: .mock.first!)
        .padding()
        .preferredColorScheme(.dark)
} 