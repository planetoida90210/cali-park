import SwiftUI

// MARK: - Parks Module
/// "Najbliższy Park": the closest real Park, or an invitation to the map when
/// the location isn't shared yet. No weather until WeatherKit arrives.
struct ParksModuleContent: View {
    let model: NearestParkViewModel

    @Environment(TabRouter.self) private var router: TabRouter?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch model.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .nearest(let item):
                nearest(item)
            case .needsLocation:
                message(Text("Włącz lokalizację na mapie Parków, a pokażemy tu najbliższy Park."),
                        systemImage: "location")
                mapButton("Otwórz mapę") { router?.selection = .parks }
            case .noParks:
                message(Text("Nie mamy jeszcze Parków do pokazania."), systemImage: "mappin.slash")
            case .failed(let text):
                message(Text(text), systemImage: "exclamationmark.triangle")
            }
        }
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }

    @ViewBuilder
    private func nearest(_ item: ParkDistance) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Najbliższy Park")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                Text(item.park.displayName)
                    .font(.bodyLarge.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                if let locality = item.park.locality.label {
                    Text(locality)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            if let meters = item.meters {
                Text(ParkFormat.distance(meters))
                    .font(.bodyMedium.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.accent)
            }
        }
        .accessibilityElement(children: .combine)
        EquipmentChips(equipment: item.park.equipment, limit: 3)
        mapButton("Pokaż na mapie") { router?.showPark(item.park.id) }
    }

    private func message(_ text: Text, systemImage: String) -> some View {
        Label { text } icon: { Image(systemName: systemImage) }
            .font(.bodyMedium)
            .foregroundStyle(Color.textSecondary)
    }

    private func mapButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.buttonMedium)
                .foregroundStyle(Color.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.glassBackground)
                .clipShape(.rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accent, lineWidth: 1)
                )
        }
    }
}

#Preview {
    let model = AppEnvironment.seeded().makeNearestParkViewModel()
    ParksModuleContent(model: model)
        .task { await model.refresh() }
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
