import SwiftUI

// MARK: - ParkSheetView
/// The Park card as a sheet over the map (ticket 023): the compact detent
/// shows name, distance, verification, "Nawiguj" and equipment; pulling it up
/// shows the rest. Read-only OSM card: no photos, reviews or weather sections
/// until the Community and WeatherKit exist (no placeholders).
struct ParkSheetView: View {
    let park: Park
    let distance: Double?
    let dataTimestamp: Date?
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                actions
                ScrollView(.horizontal) {
                    EquipmentChips(equipment: park.equipment)
                }
                .scrollIndicators(.hidden)

                Divider().overlay(Color.divider)
                equipmentSection
                sourceSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Compact part

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(park.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Zamknij", systemImage: "xmark", action: onClose)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.08), in: .circle)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            ParkVerificationBadge(verification: park.verification)
            Spacer()
            if let url = ParkFormat.appleMapsURL(for: park) {
                Button("Nawiguj", systemImage: "arrow.triangle.turn.up.right.diamond.fill") {
                    openURL(url)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.accent, in: .capsule)
                .accessibilityHint("Otwiera trasę w Mapach Apple")
            }
        }
    }

    // MARK: Full part

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sprzęt")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            if park.equipment.isEmpty {
                Text("OpenStreetMap oznacza to miejsce jako park do kalisteniki, ale nie podaje sprzętu.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                ForEach(park.equipment, id: \.type) { item in
                    HStack {
                        Label(item.type.title, systemImage: item.type.symbol)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        if let count = item.count {
                            Text("× \(count)")
                                .foregroundStyle(Color.textSecondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
            if park.hasMachines {
                Label("Obok stoją też maszyny siłowni plenerowej", systemImage: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Źródło")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            OSMAttributionLink()
            Text(sourceFooter)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var subtitle: String? {
        let parts = [park.locality.label, distance.map(ParkFormat.distance)].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var sourceFooter: String {
        var text = "Dane Parku pochodzą z OpenStreetMap i są dostępne na licencji ODbL."
        if let dataTimestamp {
            text += " \(ParkFormat.dataDate(dataTimestamp))."
        }
        return text
    }
}

#Preview {
    Color.appBackground
        .sheet(isPresented: .constant(true)) {
            ParkSheetView(
                park: Park(id: UUID(), latitude: 52.24, longitude: 21.06,
                           generatedName: "Street workout · Park Skaryszewski",
                           locality: Locality(city: "Warszawa", district: "Praga-Południe"),
                           equipment: [ParkEquipment(type: .horizontalBar, count: 3), ParkEquipment(type: .parallelBars)],
                           hasMachines: true),
                distance: 1250,
                dataTimestamp: .now,
                onClose: {}
            )
            .presentationDetents([.height(250), .large])
        }
        .preferredColorScheme(.dark)
}
