import SwiftUI

// MARK: - ParkListLocationPrompt
/// List row asking for location access so the list sorts by distance; links
/// to Settings once access was denied.
struct ParkListLocationPrompt: View {
    let authorization: LocationAuthorization
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Odległość do Parków", systemImage: "location")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            Text("Zezwól CaliPark na lokalizację, a lista ułoży się od najbliższego Parku. Twoja pozycja zostaje w telefonie.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            if authorization == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Otwórz Ustawienia") { openURL(url) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accent)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.componentBackground)
    }
}
