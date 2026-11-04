import SwiftUI

// MARK: - ParkCardSection
/// Sections of the full Park card, in the order ticket 023 decided (order A,
/// "photos first"):
///
/// photos · equipment · source ("Skąd te dane") · weather · reviews ·
/// details ("Szczegóły") · footer ("Zgłoś poprawkę")
///
/// Only the sections the read-only OSM data fills exist today. Photos and
/// reviews come with the Community backend, weather with WeatherKit, and the
/// footer's corrections with moderation: add each as a case at its place above.
enum ParkCardSection: CaseIterable, Identifiable {
    case equipment
    case source
    case details

    var id: Self { self }
}

// MARK: - ParkSheetView
/// The Park card as a sheet over the map (ticket 023), like a place in Apple
/// Maps. At the compact detent it shows the header: name, locality, distance,
/// verification badge, equipment glyphs, "Nawiguj" and "Szczegóły". Pulling
/// it up (or "Szczegóły") shows the full card below the same header.
struct ParkSheetView: View {
    let park: Park
    /// Metres from the user; nil unless location is already allowed.
    let distance: Double?
    let dataTimestamp: Date?
    let isFavorite: Bool
    let isExpanded: Bool
    /// Called with the header's height, so the compact detent fits it at any
    /// Dynamic Type size.
    let onHeaderHeightChange: (CGFloat) -> Void
    let onToggleFavorite: () -> Void
    let onExpand: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ParkCardHeader(park: park, distance: distance, isFavorite: isFavorite, isExpanded: isExpanded,
                               onToggleFavorite: onToggleFavorite, onExpand: onExpand, onClose: onClose)
                    .padding(.horizontal, 20)
                    .padding(.top, ParkSheetView.headerTopPadding)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        onHeaderHeightChange(height)
                    }

                VStack(alignment: .leading, spacing: 28) {
                    ForEach(ParkCardSection.allCases) { section in
                        sectionView(section)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
                // The compact card is the header alone; the sections show
                // once the sheet is pulled up.
                .opacity(isExpanded ? 1 : 0)
                .accessibilityHidden(!isExpanded)
                .animation(.smooth, value: isExpanded)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Space above the header, clear of the drag indicator.
    static let headerTopPadding: CGFloat = 22
    /// Extra height below the header at the compact detent. Zero, because the
    /// floating sheet already adds its bottom inset to a height detent.
    static let headerBottomPadding: CGFloat = 0

    @ViewBuilder
    private func sectionView(_ section: ParkCardSection) -> some View {
        switch section {
        case .equipment:
            ParkEquipmentSection(park: park)
        case .source:
            ParkSourceSection(park: park, dataTimestamp: dataTimestamp)
        case .details:
            ParkDetailsSection(park: park)
        }
    }
}

// MARK: - ParkCardHeader
/// Everything that fits the compact detent.
private struct ParkCardHeader: View {
    let park: Park
    let distance: Double?
    let isFavorite: Bool
    let isExpanded: Bool
    let onToggleFavorite: () -> Void
    let onExpand: () -> Void
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(park.displayName)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle = ParkFormat.subtitle(for: park, distance: distance) {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .accessibilityLabel(ParkFormat.subtitleAccessibility(for: park, distance: distance) ?? subtitle)
                    }
                }
                Spacer(minLength: 0)
                Button(isFavorite ? "Usuń z ulubionych" : "Dodaj do ulubionych",
                       systemImage: isFavorite ? "heart.fill" : "heart",
                       action: onToggleFavorite)
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isFavorite ? Color.accent : Color.textSecondary)
                    .scaledIconFrame(32, relativeTo: .subheadline)
                    .background(Color.controlFill, in: .circle)
                    .buttonStyle(.plain)
                    .contentTransition(.symbolEffect(.replace))
                    .sensoryFeedback(.selection, trigger: isFavorite)
                    .accessibilityAddTraits(isFavorite ? .isSelected : [])
                Button("Zamknij", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .scaledIconFrame(32, relativeTo: .subheadline)
                    .background(Color.controlFill, in: .circle)
                    .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                ParkVerificationBadge(verification: park.verification)
                Spacer(minLength: 0)
                ParkEquipmentGlyphs(equipment: park.equipment)
            }

            HStack(spacing: 10) {
                if let url = ParkFormat.appleMapsURL(for: park) {
                    Button("Nawiguj", systemImage: "arrow.triangle.turn.up.right.diamond.fill") {
                        openURL(url)
                    }
                    .buttonStyle(ParkCardButtonStyle(isProminent: true))
                    .accessibilityHint("Otwiera trasę w Mapach Apple")
                }
                if !isExpanded {
                    Button("Szczegóły", systemImage: "chevron.up", action: onExpand)
                    .buttonStyle(ParkCardButtonStyle(isProminent: false))
                    .accessibilityHint("Rozwija pełną kartę Parku")
                }
            }
        }
    }
}

// MARK: - ParkEquipmentGlyphs
/// Up to four equipment glyphs and "+2"; one VoiceOver element naming them.
struct ParkEquipmentGlyphs: View {
    let equipment: [ParkEquipment]
    var limit = 4

    @ScaledMetric(relativeTo: .subheadline) private var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 4) {
            ForEach(equipment.prefix(limit), id: \.type) { item in
                Image(systemName: item.type.symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.accent)
                    .frame(width: size, height: size)
                    .background(Color.controlFill, in: .circle)
            }
            if equipment.count > limit {
                Text("+\(equipment.count - limit)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ParkFormat.equipmentSummary(equipment, shown: limit))
    }
}

// MARK: - ParkCardButtonStyle
/// The card's capsule buttons: lime "Nawiguj", grey secondary actions. The
/// whole capsule is the tap target.
struct ParkCardButtonStyle: ButtonStyle {
    let isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isProminent ? Color.black : Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isProminent ? Color.accent : Color.controlFill, in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Previews
#Preview("Rich OSM data") {
    ParkSheetPreview(park: Park(
        id: UUID(), latitude: 50.285, longitude: 18.594,
        osmRefs: ["n13608564606"],
        generatedName: "Street workout · Skwer Młodego Strażaka",
        locality: Locality(city: "Gliwice", district: "Ostropa"),
        equipment: [ParkEquipment(type: .horizontalBar, count: 7, heights: [.low, .high]),
                    ParkEquipment(type: .parallelBars, count: 2),
                    ParkEquipment(type: .rings),
                    ParkEquipment(type: .horizontalLadder),
                    ParkEquipment(type: .wallBars, count: 2),
                    ParkEquipment(type: .climbingPole)],
        hasMachines: true, surface: .rubber, lit: false, openingHours: "Mo-Su 06:00-22:00"
    ), distance: 1250)
}

#Preview("Sparse OSM data, no location") {
    ParkSheetPreview(park: Park(
        id: UUID(), latitude: 52.23, longitude: 20.97,
        osmRefs: ["w123456"],
        generatedName: "Drążki · ul. Kasprzaka",
        locality: Locality(city: "Warszawa", district: "Wola"),
        equipment: [ParkEquipment(type: .horizontalBar)]
    ), distance: nil)
}

private struct ParkSheetPreview: View {
    let park: Park
    let distance: Double?
    @State private var detent: PresentationDetent = .large
    @State private var isFavorite = false

    var body: some View {
        Color.appBackground
            .sheet(isPresented: .constant(true)) {
                ParkSheetView(park: park, distance: distance, dataTimestamp: .now,
                              isFavorite: isFavorite, isExpanded: detent == .large,
                              onHeaderHeightChange: { _ in }, onToggleFavorite: { isFavorite.toggle() },
                              onExpand: { detent = .large }, onClose: {})
                    .presentationDetents([.height(260), .large], selection: $detent)
            }
            .preferredColorScheme(.dark)
    }
}
