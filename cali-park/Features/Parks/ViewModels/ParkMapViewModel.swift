import CoreLocation
import MapKit
import Observation
import SwiftUI

// MARK: - ParkMapViewModel
/// The Parks tab ("Siłownie"): a read-only map and list of Parks from the
/// bundled OSM snapshot, with distances when the user shares their location.
@MainActor
@Observable
final class ParkMapViewModel {
    enum Mode: Hashable {
        case map, list
    }

    /// Whole Poland, used until (or unless) the user's position is known. No
    /// fake "you are here".
    static let fallbackRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.0, longitude: 19.3),
        span: MKCoordinateSpan(latitudeDelta: 6.4, longitudeDelta: 9.6)
    )
    /// Zoom around the user's position on first open: a few kilometres.
    static let userSpan = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    /// Zoom when a Park is selected; never zooms out a closer view.
    static let selectionSpan: CLLocationDegrees = 0.02

    static let loadErrorMessage = "Nie udało się wczytać Parków. Spróbuj ponownie później."

    // MARK: State

    private(set) var parks: [Park] = []
    private(set) var dataTimestamp: Date?
    private(set) var isLoaded = false
    var errorMessage: String?

    var searchText = ""
    var mode: Mode = .map
    var selectedParkID: UUID?

    private(set) var authorization: LocationAuthorization
    private(set) var userLocation: CLLocationCoordinate2D?

    /// Camera binding for `Map`.
    var position: MapCameraPosition
    /// The region the map last settled on; drives clustering.
    private(set) var visibleRegion: MKCoordinateRegion

    // MARK: Dependencies

    private let directory: ParkDirectory
    private let location: LocationProviding
    /// Set once the camera moved for a reason the user cares about (their
    /// position, a selection, a search), so a late location fix doesn't yank
    /// the map away.
    private var hasPlacedCamera = false
    private var pendingFocusID: UUID?

    init(directory: ParkDirectory, location: LocationProviding) {
        self.directory = directory
        self.location = location
        authorization = location.authorization
        position = .region(Self.fallbackRegion)
        visibleRegion = Self.fallbackRegion
    }

    // MARK: Derived

    /// Parks matching the search, for the map.
    var filteredParks: [Park] {
        ParkSearch.matching(parks, query: searchText)
    }

    /// Parks matching the search, nearest first when the position is known.
    var listItems: [ParkDistance] {
        ParkSearch.ordered(filteredParks, from: userLocation)
    }

    /// True while the search field holds more than whitespace.
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Up to five matches under the search field on the map.
    var searchSuggestions: [ParkDistance] {
        guard isSearching else { return [] }
        return Array(listItems.prefix(5))
    }

    var clusters: [ParkCluster] {
        ParkClustering.clusters(for: filteredParks, in: visibleRegion, selectedID: selectedParkID)
    }

    var selectedPark: Park? {
        selectedParkID.flatMap(park(withID:))
    }

    func park(withID id: UUID) -> Park? {
        parks.first { $0.id == id }
    }

    func distance(to park: Park) -> CLLocationDistance? {
        userLocation.map { ParkSearch.distance(from: $0, to: park) }
    }

    // MARK: Lifecycle

    /// First open of the tab: load Parks, then ask for location once (the
    /// only place the app shows the location prompt).
    func start() async {
        await load()
        await updateLocation(prompting: true)
    }

    /// Back in the app: pick up a permission change made in Settings. Never
    /// prompts.
    func refreshLocation() async {
        await updateLocation(prompting: false)
    }

    func load() async {
        guard !isLoaded else { return }
        do {
            let catalog = try await directory.catalog()
            parks = catalog.parks
            dataTimestamp = catalog.dataTimestamp
            isLoaded = true
            errorMessage = nil
            applyPendingFocus()
        } catch {
            errorMessage = Self.loadErrorMessage
        }
    }

    private func updateLocation(prompting: Bool) async {
        var state = location.authorization
        if state == .notDetermined && prompting {
            state = await location.requestAuthorization()
        }
        authorization = state
        guard state == .authorized else {
            userLocation = nil
            return
        }
        guard let coordinate = await location.currentLocation() else { return }
        userLocation = coordinate
        if !hasPlacedCamera {
            move(to: MKCoordinateRegion(center: coordinate, span: Self.userSpan))
        }
    }

    // MARK: Map interaction

    func cameraDidChange(to region: MKCoordinateRegion) {
        visibleRegion = region
    }

    func select(_ park: Park) {
        selectedParkID = park.id
        let span = min(visibleRegion.span.latitudeDelta, Self.selectionSpan)
        move(to: MKCoordinateRegion(center: park.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)))
    }

    func clearSelection() {
        selectedParkID = nil
    }

    /// Zooms into a cluster bubble. Always zooms in at least 2×, so a bubble of
    /// Parks closer than one grid cell still splits.
    func zoom(into cluster: ParkCluster) {
        guard let fitted = ParkClustering.region(fitting: cluster.parks) else { return }
        let maxSpan = visibleRegion.span.latitudeDelta / 2
        let latitudeDelta = min(fitted.span.latitudeDelta, maxSpan)
        let longitudeDelta = min(fitted.span.longitudeDelta, visibleRegion.span.longitudeDelta / 2)
        move(to: MKCoordinateRegion(center: fitted.center,
                                    span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)))
    }

    /// Search "Enter": one match opens it, several frame them all.
    func submitSearch() {
        let matches = filteredParks
        if matches.count == 1, let only = matches.first {
            select(only)
        } else if let region = ParkClustering.region(fitting: matches) {
            selectedParkID = nil
            move(to: region)
        }
    }

    /// From a search suggestion or the Home module: show this Park on the map.
    func focus(on parkID: UUID) {
        guard isLoaded else {
            pendingFocusID = parkID
            return
        }
        guard let park = park(withID: parkID) else { return }
        searchText = ""
        mode = .map
        select(park)
    }

    func toggleMode() {
        mode = mode == .map ? .list : .map
    }

    // MARK: Private

    private func move(to region: MKCoordinateRegion) {
        hasPlacedCamera = true
        position = .region(region)
        visibleRegion = region
    }

    private func applyPendingFocus() {
        guard let id = pendingFocusID else { return }
        pendingFocusID = nil
        focus(on: id)
    }
}
