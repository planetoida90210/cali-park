import SwiftUI
import MapKit

// MARK: - ParkDetailView
struct ParkDetailView: View {
    // Park przekazywany z listy
    let park: Park
    // Premium status – w przyszłości pobierzemy z konta użytkownika
    var isPremiumUser: Bool = false

    @EnvironmentObject private var parksVM: ParksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showReportSheet = false

    // Mock – pierwsze nadchodzące wydarzenie
    private var upcomingEvent: (title: String, date: String)? {
        // To będzie pobierane z API
        return ("Trening grupowy", "Sobota • 10:00")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                gallerySection
                ratingSection
                equipmentSection
                navigationSection
                if let event = upcomingEvent { eventSection(event) }
                actionsSection
            }
            .padding(16)
        }
        .background(Color.appBackground)
        .navigationTitle(park.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
        .sheet(isPresented: $showReportSheet) {
            ReportParkView(park: park)
        }
    }

    // MARK: - Sections
    private var gallerySection: some View {
        TabView {
            if park.images.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.textSecondary)
                    Text("Brak zdjęć")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                    if !isPremiumUser {
                        premiumCTA
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.componentBackground)
            } else {
                ForEach(park.images, id: \ .self) { url in
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Color.gray.opacity(0.2)
                        }
                    }
                }
            }
        }
        .frame(height: 240)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var premiumCTA: some View {
        Button(action: {/* paywall */}) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                Text("Dodaj zdjęcie (Premium)")
            }
            .font(.caption.weight(.semibold))
            .padding(8)
            .foregroundColor(.black)
            .background(Color.accent)
            .clipShape(Capsule())
        }
    }

    private var ratingSection: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.accent)
            Text(String(format: "%.1f", park.rating))
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            Spacer()
            Button(action: { parksVM.toggleFavorite(for: park) }) {
                Image(systemName: park.isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(park.isFavorite ? .accent : .textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wyposażenie")
                .font(.bodyMedium).foregroundColor(.textPrimary)
            if park.equipments.isEmpty {
                Text("Brak danych")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            } else {
                ForEach(park.equipments, id: \ .self) { item in
                    Text("• \(item)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    private var navigationSection: some View {
        Button(action: openInMaps) {
            Label("Nawiguj", systemImage: "car.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private func eventSection(_ event: (title: String, date: String)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wydarzenie")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.accent)
                    Text(event.date)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Button("Zapisz się") {}
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accent)
                    .clipShape(Capsule())
            }
            .padding(12)
            .background(Color.componentBackground)
            .cornerRadius(8)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) { showReportSheet = true } label: {
                Label("Zgłoś problem", systemImage: "exclamationmark.bubble")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Helpers
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: park.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = park.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - Report View (mock)
private struct ReportParkView: View {
    let park: Park
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Text("Raportowanie jeszcze w przygotowaniu ✌️")
                .padding()
                .navigationTitle("Zgłoś park")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ParkDetailView(park: .mock.first!)
            .environmentObject(ParksViewModel())
    }
    .preferredColorScheme(.dark)
} 