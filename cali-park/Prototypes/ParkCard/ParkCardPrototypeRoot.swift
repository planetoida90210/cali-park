#if DEBUG
// PROTOTYPE — throwaway. Ticket: docs/wayfinder/calipark-1.0/tickets/023-park-card.md
//
// Clickable Park card on the variant A ("Wyciszona") map. Tapping a pin opens a sheet:
// the compact card sits at a low detent over the map, and dragging it up (or "Szczegóły")
// shows the full card. Two section orders: A "Zdjęcia najpierw" and B "Sprzęt najpierw".
//
// Launch arguments (DEBUG builds only):
//   -PrototypeParkCard                        show this prototype instead of the app
//   -ParkCardPark rich|community|osm|pending  open with this Park selected
//   -ParkCardOrder photos|equipment           section order A or B (default: photos)
//   -ParkCardDetent compact|full              sheet height at launch (default: compact)
//   -ParkCardScroll <section>                 scroll the full card to photos|equipment|
//                                             verification|weather|reviews|facts|footer
//   -ParkCardModal <name>                     open a sheet on top, used for screenshots: correction,
//                                             correction-equipment, correction-gone, report-photo,
//                                             report-review, review, add-photo, photo
//   -ParkCardClean                            hide the prototype switcher pill

import MapKit
import SwiftUI

struct ParkCardLaunchOptions {
    let isEnabled: Bool
    let parkID: String?
    let order: CardOrder
    let startsFull: Bool
    let scrollTarget: CardSection?
    let modal: String?
    let hidesSwitcher: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        isEnabled = arguments.contains("-PrototypeParkCard")
        parkID = value(after: "-ParkCardPark")
        order = value(after: "-ParkCardOrder").flatMap(CardOrder.init(rawValue:)) ?? .photos
        startsFull = value(after: "-ParkCardDetent") == "full"
        scrollTarget = value(after: "-ParkCardScroll").flatMap(CardSection.init(rawValue:))
        modal = value(after: "-ParkCardModal")
        hidesSwitcher = arguments.contains("-ParkCardClean")
    }
}

// MARK: - Order and sections

enum CardSection: String, CaseIterable, Identifiable, Hashable {
    case photos, equipment, verification, weather, reviews, facts, footer

    var id: String { rawValue }
}

enum CardOrder: String, CaseIterable, Identifiable, Hashable {
    /// A: the brief's order, photos first.
    case photos
    /// B: "can I train here now" first, Community content lower.
    case equipment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photos: "A · Zdjęcia najpierw"
        case .equipment: "B · Sprzęt najpierw"
        }
    }

    var sections: [CardSection] {
        switch self {
        case .photos: [.photos, .equipment, .verification, .weather, .reviews, .facts, .footer]
        case .equipment: [.equipment, .weather, .facts, .reviews, .photos, .verification, .footer]
        }
    }

    var other: CardOrder { self == .photos ? .equipment : .photos }
}

// MARK: - Modals

enum ReportTarget: Hashable {
    case photo(CardPhoto)
    case review(CardReview)
}

enum ParkCardModal: Identifiable, Hashable {
    case correction(CorrectionKind?)
    case report(ReportTarget)
    case review
    case addPhoto

    var id: String {
        switch self {
        case .correction(let kind): "correction-\(kind?.rawValue ?? "pick")"
        case .report(.photo(let photo)): "report-photo-\(photo.id)"
        case .report(.review(let review)): "report-review-\(review.id)"
        case .review: "review"
        case .addPhoto: "add-photo"
        }
    }
}

struct PhotoViewerItem: Identifiable, Hashable {
    let startID: Int
    var id: Int { startID }
}

// MARK: - Model

@MainActor
@Observable
final class ParkCardPrototypeModel {
    static let compactDetent = PresentationDetent.height(176)

    var parks: [CardPark] = ParkCardSampleData.parks
    var selectedID: String?
    var detent: PresentationDetent = ParkCardPrototypeModel.compactDetent
    var order: CardOrder = .photos
    var scrollTarget: CardSection?
    /// Launch-argument modal, opened once the card sheet is on screen.
    var pendingModal: String?
    var modal: ParkCardModal?
    var viewer: PhotoViewerItem?
    var showsAllReviews = false
    var position: MapCameraPosition = .region(MapLookSampleData.initialRegion)

    var selectedPark: CardPark? {
        parks.first { $0.id == selectedID }
    }

    var isSheetPresented: Bool {
        get { selectedID != nil }
        set { if !newValue { selectedID = nil } }
    }

    var isFull: Bool { detent == .large }

    func select(_ id: String?) {
        selectedID = id
        detent = Self.compactDetent
        showsAllReviews = false
        guard let park = selectedPark else { return }
        // Keep the pin above the compact card.
        let span = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        let center = CLLocationCoordinate2D(latitude: park.latitude - span.latitudeDelta * 0.22, longitude: park.longitude)
        withAnimation(.smooth) {
            position = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    func apply(modal name: String) {
        guard let park = selectedPark else { return }
        switch name {
        case "correction": modal = .correction(nil)
        case "correction-equipment": modal = .correction(.equipment)
        case "correction-gone": modal = .correction(.gone)
        case "report-photo": if let photo = park.photos.last { modal = .report(.photo(photo)) }
        case "report-review": if let review = park.reviews.first { modal = .report(.review(review)) }
        case "review": modal = .review
        case "add-photo": modal = .addPhoto
        case "photo": if let photo = park.photos.first(where: { !$0.isTeamPhoto }) { viewer = PhotoViewerItem(startID: photo.id) }
        default: break
        }
    }

    private func update(_ change: (inout CardPark) -> Void) {
        guard let index = parks.firstIndex(where: { $0.id == selectedID }) else { return }
        change(&parks[index])
    }

    func sendCorrection(_ correction: CardCorrection) {
        update { $0.correction = correction }
    }

    func withdrawCorrection() {
        update { $0.correction = nil }
    }

    func addPhoto() {
        update { park in
            let id = (park.photos.map(\.id).max() ?? 0) + 1
            park.photos.append(CardPhoto(
                id: id, scene: id, author: ParkCardSampleData.nickname,
                takenAt: ParkCardSampleData.now, isPendingModeration: true
            ))
        }
    }

    func addReview(rating: Int, text: String) {
        update { park in
            let id = (park.reviews.map(\.id).max() ?? 0) + 1
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            park.reviews.insert(CardReview(
                id: id, author: ParkCardSampleData.nickname, rating: rating,
                date: ParkCardSampleData.now, text: trimmed.isEmpty ? nil : trimmed, isMine: true
            ), at: 0)
        }
    }
}

// MARK: - Root

struct ParkCardPrototypeRoot: View {
    let options: ParkCardLaunchOptions
    @State private var model: ParkCardPrototypeModel

    init(options: ParkCardLaunchOptions) {
        self.options = options
        let model = ParkCardPrototypeModel()
        model.order = options.order
        if let parkID = options.parkID {
            model.select(parkID)
            if options.startsFull { model.detent = .large }
            model.scrollTarget = options.scrollTarget
            model.pendingModal = options.modal
        }
        _model = State(initialValue: model)
    }

    var body: some View {
        ParkCardMap(model: model)
            .safeAreaInset(edge: .top, spacing: 8) {
                VStack(spacing: 8) {
                    if !options.hidesSwitcher {
                        ParkCardSwitcherPill(model: model)
                    }
                    ParkCardSearchBar()
                }
            }
            .sheet(isPresented: $model.isSheetPresented) {
                ParkCardSheet(model: model, hidesSwitcher: options.hidesSwitcher)
            }
            .preferredColorScheme(.dark)
    }
}

// MARK: - Map

private struct ParkCardMap: View {
    @Bindable var model: ParkCardPrototypeModel

    var body: some View {
        Map(position: $model.position) {
            Annotation("Tu jesteś", coordinate: ParkCardSampleData.userLocation, anchor: .center) {
                MapLookUserDot()
            }
            .annotationTitles(.hidden)

            ForEach(model.parks) { park in
                Annotation(park.displayName, coordinate: park.coordinate, anchor: .bottom) {
                    Button {
                        model.select(park.id)
                    } label: {
                        ParkCardPin(park: park, isSelected: park.id == model.selectedID)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(park.displayName)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

/// Variant A pin. A verified Park gets a small seal; an OSM-only Park with unknown
/// equipment is dimmer, so trust is visible before tapping.
private struct ParkCardPin: View {
    let park: CardPark
    let isSelected: Bool

    var body: some View {
        let dim = park.verification == .osm && park.equipment.isEmpty && !isSelected
        VStack(spacing: -3) {
            Image(systemName: park.pinSymbol)
                .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.black : Color.accent.opacity(dim ? 0.6 : 1))
                .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                .background(isSelected ? Color.accent : Color.componentBackground, in: .circle)
                .overlay(Circle().stroke(Color.accent.opacity(isSelected ? 0 : (dim ? 0.4 : 0.85)), lineWidth: 1.5))
                .overlay(alignment: .topTrailing) {
                    if case .verified = park.verification {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.black, Color.accent)
                            .offset(x: 4, y: -4)
                    }
                }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? Color.accent : Color.componentBackground)
        }
        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

private struct ParkCardSearchBar: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
            Text("Szukaj Parku lub dzielnicy")
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(Color.accent)
                .accessibilityLabel("Filtry")
        }
        .font(.body)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .mapLookGlass(in: .capsule)
        .padding(.horizontal)
    }
}

// MARK: - Prototype switcher

/// Deliberately looks unlike the app (white pill) so it reads as prototype chrome.
struct ParkCardSwitcherPill: View {
    @Bindable var model: ParkCardPrototypeModel

    private static let labels: [(id: String, title: String)] = [
        ("rich", "Bogaty, zweryfikowany"),
        ("community", "Ze Społeczności"),
        ("osm", "Tylko OSM, bez danych"),
        ("pending", "Z poprawką w toku"),
    ]

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(Self.labels, id: \.id) { item in
                    Button(item.title) { model.select(item.id) }
                }
            } label: {
                Label(Self.labels.first { $0.id == model.selectedID }?.title ?? "Wybierz Park", systemImage: "mappin")
            }
            Divider().frame(height: 16)
            Button {
                model.order = model.order.other
            } label: {
                Label(model.order.title, systemImage: "arrow.left.arrow.right")
            }
        }
        .font(.footnote.monospaced())
        .buttonStyle(.borderless)
        .foregroundStyle(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white, in: .capsule)
        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
        .frame(maxWidth: .infinity)
    }
}
#endif
