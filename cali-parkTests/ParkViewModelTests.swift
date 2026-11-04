import CoreLocation
import Foundation
import MapKit
import Testing
@testable import cali_park

// MARK: - ParkMapViewModel

@MainActor
struct ParkMapViewModelTests {
    private func makeViewModel(
        authorization: LocationAuthorization,
        answer: LocationAuthorization = .authorized,
        parks: [Park] = ParkFixtures.all,
        error: ParkDirectoryError? = nil
    ) -> (ParkMapViewModel, FixedLocationProvider) {
        let location = FixedLocationProvider(authorization: authorization,
                                             location: ParkFixtures.warsawCentre,
                                             answer: answer)
        let directory = InMemoryParkDirectory(parks: parks, dataTimestamp: Date(timeIntervalSince1970: 1_793_749_662),
                                              error: error)
        let favorites = ParkFavorites(store: InMemoryFavoriteParkStore())
        return (ParkMapViewModel(directory: directory, location: location, favorites: favorites), location)
    }

    @Test func firstOpenAsksForLocationOnceAndCentresOnTheUser() async throws {
        let (viewModel, location) = makeViewModel(authorization: .notDetermined, answer: .authorized)

        await viewModel.start()

        #expect(location.requestCount == 1)
        #expect(viewModel.authorization == .authorized)
        #expect(viewModel.userLocation?.latitude == ParkFixtures.warsawCentre.latitude)
        let region = try #require(viewModel.position.region)
        #expect(region.center.latitude == ParkFixtures.warsawCentre.latitude)
        #expect(region.span.latitudeDelta == ParkMapViewModel.userSpan.latitudeDelta)
        #expect(viewModel.listItems.first?.park.id == ParkFixtures.mokotowID)
        #expect(viewModel.listItems.allSatisfy { $0.meters != nil })
    }

    @Test func deniedLocationKeepsThePolandViewAndShowsNoDistances() async throws {
        let (viewModel, location) = makeViewModel(authorization: .notDetermined, answer: .denied)

        await viewModel.start()

        #expect(location.requestCount == 1)
        #expect(viewModel.authorization == .denied)
        #expect(viewModel.userLocation == nil)
        let region = try #require(viewModel.position.region)
        #expect(region.center.latitude == ParkMapViewModel.fallbackRegion.center.latitude)
        #expect(viewModel.listItems.allSatisfy { $0.meters == nil })
        #expect(viewModel.distance(to: ParkFixtures.mokotow) == nil)
    }

    @Test func anAnsweredPromptIsNeverShownAgain() async {
        let (viewModel, location) = makeViewModel(authorization: .denied)

        await viewModel.start()

        #expect(location.requestCount == 0)
        #expect(viewModel.authorization == .denied)
    }

    @Test func returningToTheAppPicksUpPermissionWithoutPrompting() async {
        let (viewModel, location) = makeViewModel(authorization: .notDetermined)

        await viewModel.refreshLocation()
        #expect(location.requestCount == 0)
        #expect(viewModel.userLocation == nil)

        // The user allowed location in Settings meanwhile.
        location.authorization = .authorized
        await viewModel.refreshLocation()
        #expect(viewModel.userLocation != nil)
    }

    @Test func aLateFixDoesNotMoveACameraTheUserAlreadyMoved() async throws {
        let location = FixedLocationProvider(authorization: .authorized, location: ParkFixtures.warsawCentre)
        let second = ParkMapViewModel(directory: InMemoryParkDirectory(parks: ParkFixtures.all), location: location,
                                      favorites: ParkFavorites(store: InMemoryFavoriteParkStore()))
        await second.load()
        second.select(ParkFixtures.krakow)
        await second.refreshLocation()

        let region = try #require(second.position.region)
        #expect(region.center.latitude == ParkFixtures.krakow.latitude)
        #expect(second.userLocation != nil)
    }

    @Test func loadFailureShowsAnErrorInsteadOfAnEmptyMap() async {
        let (viewModel, _) = makeViewModel(authorization: .denied, error: .missingSnapshot)

        await viewModel.start()

        #expect(viewModel.errorMessage == ParkMapViewModel.loadErrorMessage)
        #expect(viewModel.isLoaded == false)
        #expect(viewModel.parks.isEmpty)
    }

    @Test func loadKeepsTheDataDate() async {
        let (viewModel, _) = makeViewModel(authorization: .denied)
        await viewModel.load()
        #expect(viewModel.dataTimestamp == Date(timeIntervalSince1970: 1_793_749_662))
    }

    @Test func selectingAParkZoomsInButNeverOut() async throws {
        let (viewModel, _) = makeViewModel(authorization: .denied)
        await viewModel.load()

        viewModel.select(ParkFixtures.praga)
        #expect(viewModel.selectedPark == ParkFixtures.praga)
        #expect(try #require(viewModel.position.region).span.latitudeDelta == ParkMapViewModel.selectionSpan)

        viewModel.cameraDidChange(to: MKCoordinateRegion(center: ParkFixtures.praga.coordinate,
                                                         span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        viewModel.select(ParkFixtures.mokotow)
        #expect(try #require(viewModel.position.region).span.latitudeDelta == 0.005)

        viewModel.clearSelection()
        #expect(viewModel.selectedPark == nil)
    }

    @Test func searchFiltersMapAndListAndSuggestsAtMostFive() async {
        let many = (0..<8).map { index in
            ParkFixtures.park(latitude: 52 + Double(index) * 0.01, longitude: 21,
                              generatedName: "Drążki · ul. Testowa \(index)", city: "Warszawa")
        }
        let (viewModel, _) = makeViewModel(authorization: .denied, parks: ParkFixtures.all + many)
        await viewModel.load()

        #expect(viewModel.searchSuggestions.isEmpty)
        viewModel.searchText = "testowa"
        #expect(viewModel.filteredParks.count == 8)
        #expect(viewModel.listItems.count == 8)
        #expect(viewModel.searchSuggestions.count == 5)
    }

    @Test func submittingASearchWithOneMatchSelectsIt() async {
        let (viewModel, _) = makeViewModel(authorization: .denied)
        await viewModel.load()

        viewModel.searchText = "jordana"
        viewModel.submitSearch()

        #expect(viewModel.selectedParkID == ParkFixtures.krakowID)
    }

    @Test func submittingASearchWithSeveralMatchesFramesThem() async throws {
        let (viewModel, _) = makeViewModel(authorization: .denied)
        await viewModel.load()
        viewModel.select(ParkFixtures.krakow)

        viewModel.searchText = "warszawa"
        viewModel.submitSearch()

        #expect(viewModel.selectedParkID == nil)
        let region = try #require(viewModel.position.region)
        for park in [ParkFixtures.mokotow, ParkFixtures.praga] {
            #expect(abs(park.latitude - region.center.latitude) <= region.span.latitudeDelta / 2)
        }
    }

    @Test func focusRequestedBeforeLoadingIsAppliedAfterwards() async {
        let (viewModel, _) = makeViewModel(authorization: .denied)
        viewModel.mode = .list
        viewModel.searchText = "kraków"

        viewModel.focus(on: ParkFixtures.pragaID)
        #expect(viewModel.selectedParkID == nil)

        await viewModel.load()
        #expect(viewModel.selectedParkID == ParkFixtures.pragaID)
        #expect(viewModel.mode == .map)
        #expect(viewModel.searchText.isEmpty)
    }

    @Test func zoomingIntoAClusterAlwaysZoomsIn() async throws {
        let (viewModel, _) = makeViewModel(authorization: .denied)
        await viewModel.load()
        let wide = MKCoordinateRegion(center: ParkFixtures.warsawCentre,
                                      span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004))
        viewModel.cameraDidChange(to: wide)

        viewModel.zoom(into: ParkCluster(parks: [ParkFixtures.mokotow, ParkFixtures.praga]))

        #expect(try #require(viewModel.position.region).span.latitudeDelta <= 0.002)
    }

    @Test func toggleSwitchesBetweenMapAndList() {
        let (viewModel, _) = makeViewModel(authorization: .denied)
        #expect(viewModel.mode == .map)
        viewModel.toggleMode()
        #expect(viewModel.mode == .list)
        viewModel.toggleMode()
        #expect(viewModel.mode == .map)
    }
}

// MARK: - NearestParkViewModel

@MainActor
struct NearestParkViewModelTests {
    @Test func showsTheNearestParkWhenLocationIsAllowed() async {
        let location = FixedLocationProvider(authorization: .authorized, location: ParkFixtures.warsawCentre)
        let model = NearestParkViewModel(directory: InMemoryParkDirectory(parks: ParkFixtures.all), location: location)

        await model.refresh()

        guard case .nearest(let item) = model.state else {
            Issue.record("Expected a nearest Park, got \(model.state)")
            return
        }
        #expect(item.park.id == ParkFixtures.mokotowID)
        #expect(item.meters != nil)
    }

    @Test(arguments: [LocationAuthorization.notDetermined, .denied])
    func withoutPermissionInvitesToTheMapAndNeverPrompts(authorization: LocationAuthorization) async {
        let location = FixedLocationProvider(authorization: authorization, location: ParkFixtures.warsawCentre)
        let model = NearestParkViewModel(directory: InMemoryParkDirectory(parks: ParkFixtures.all), location: location)

        await model.refresh()

        #expect(model.state == .needsLocation)
        #expect(location.requestCount == 0)
    }

    @Test func noFixInvitesToTheMap() async {
        let location = FixedLocationProvider(authorization: .authorized, location: nil)
        let model = NearestParkViewModel(directory: InMemoryParkDirectory(parks: ParkFixtures.all), location: location)

        await model.refresh()

        #expect(model.state == .needsLocation)
    }

    @Test func emptyDirectory() async {
        let location = FixedLocationProvider(authorization: .authorized, location: ParkFixtures.warsawCentre)
        let model = NearestParkViewModel(directory: InMemoryParkDirectory(), location: location)

        await model.refresh()

        #expect(model.state == .noParks)
    }

    @Test func unreadableDirectoryShowsAnError() async {
        let location = FixedLocationProvider(authorization: .authorized, location: ParkFixtures.warsawCentre)
        let model = NearestParkViewModel(directory: InMemoryParkDirectory(error: .missingSnapshot), location: location)

        await model.refresh()

        #expect(model.state == .failed(ParkMapViewModel.loadErrorMessage))
    }
}

// MARK: - Cross-tab navigation and location mapping

@MainActor
struct ParkNavigationTests {
    @Test func showParkSwitchesToTheParksTab() {
        let router = TabRouter(selection: .home)
        router.showPark(ParkFixtures.pragaID)
        #expect(router.selection == .parks)
        #expect(router.parkToFocus == ParkFixtures.pragaID)
    }

    @Test(arguments: [
        (CLAuthorizationStatus.notDetermined, LocationAuthorization.notDetermined),
        (.authorizedWhenInUse, .authorized),
        (.authorizedAlways, .authorized),
        (.denied, .denied),
        (.restricted, .denied)
    ])
    func coreLocationStatusMapping(status: CLAuthorizationStatus, expected: LocationAuthorization) {
        #expect(CoreLocationProvider.authorization(from: status) == expected)
    }
}
