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
                ParkHeroHeaderView(park: park, isPremiumUser: isPremiumUser)
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
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wyposażenie")
                .font(.bodyMedium).foregroundColor(.textPrimary)
            if park.equipments.isEmpty {
                Text("Brak danych")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            } else {
                ForEach(park.equipments, id: \.self) { item in
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