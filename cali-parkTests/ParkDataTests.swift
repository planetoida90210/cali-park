import CoreLocation
import Foundation
import MapKit
import Testing
@testable import cali_park

// MARK: - Snapshot decoding

struct ParkSnapshotTests {
    private let json = """
    {
      "schemaVersion": 1,
      "osmDataTimestamp": "2026-11-03T23:47:42Z",
      "parks": [
        {
          "id": "D0000000-0000-4000-8000-0000000000A1",
          "status": "published", "verification": "osm", "source": "osm",
          "latitude": 52.2, "longitude": 21.0,
          "osmRefs": ["w1", "n2"],
          "name": null,
          "generatedName": "Street workout · Park Dreszera",
          "locality": {"city": "Warszawa", "district": "Mokotów"},
          "equipment": [
            {"type": "horizontal_bar", "count": 3},
            {"type": "jetpack", "count": null},
            {"type": "parallel_bars"}
          ],
          "isCalisthenicsTagged": true, "hasMachines": true,
          "surface": "moon_dust", "lit": true, "covered": null,
          "access": "public", "openingHours": "06:00-22:00"
        },
        {
          "id": "D0000000-0000-4000-8000-0000000000A2",
          "status": "removed", "verification": "osm", "source": "osm",
          "latitude": 50.0, "longitude": 19.9,
          "generatedName": "Drążki · Kraków",
          "equipment": [{"type": "horizontal_bar"}]
        }
      ]
    }
    """

    @Test func decodesParksAndKeepsOnlyPublished() throws {
        let catalog = try ParkSnapshot.decode(Data(json.utf8)).catalog

        #expect(catalog.parks.count == 1)
        #expect(catalog.dataTimestamp == Date(timeIntervalSince1970: 1_793_749_662))
        let park = try #require(catalog.parks.first)
        #expect(park.osmRefs == ["w1", "n2"])
        #expect(park.displayName == "Street workout · Park Dreszera")
        #expect(park.locality == Locality(city: "Warszawa", district: "Mokotów"))
        #expect(park.isCalisthenicsTagged)
        #expect(park.hasMachines)
        #expect(park.lit == true)
        #expect(park.covered == nil)
        #expect(park.openingHours == "06:00-22:00")
    }

    @Test func dropsUnknownEquipmentAndSurfaceInsteadOfFailing() throws {
        let park = try #require(try ParkSnapshot.decode(Data(json.utf8)).parks.first)

        #expect(park.equipment == [ParkEquipment(type: .horizontalBar, count: 3), ParkEquipment(type: .parallelBars)])
        #expect(park.surface == nil)
    }

    @Test func missingOptionalFieldsGetSafeDefaults() throws {
        let park = try #require(try ParkSnapshot.decode(Data(json.utf8)).parks.last)

        #expect(park.osmRefs.isEmpty)
        #expect(park.equipment == [ParkEquipment(type: .horizontalBar)])
        #expect(!park.isCalisthenicsTagged)
        #expect(!park.hasMachines)
        #expect(park.access == .public)
        #expect(park.locality == Locality())
    }

    /// Owner's addendum to 012 (Q28): a place without a pull-up bar or
    /// parallel bars in the data is not a Park, even when tagged
    /// `sport=calisthenics`. Such entries are dropped, like unknown keys.
    @Test func dropsEntriesWithoutCoreEquipment() throws {
        func entry(_ id: Int, equipment: String) -> String {
            """
            {"id": "D0000000-0000-4000-8000-00000000000\(id)", "status": "published",
             "verification": "osm", "source": "osm", "latitude": 52, "longitude": 21,
             "generatedName": "Park \(id)", "isCalisthenicsTagged": true, "equipment": \(equipment)}
            """
        }
        let parks = [
            entry(1, equipment: "[]"),
            entry(2, equipment: #"[{"type": "rings"}, {"type": "wall_bars"}]"#),
            entry(3, equipment: #"[{"type": "jetpack"}, {"type": "sit-up"}]"#),
            entry(4, equipment: "null"),
            entry(5, equipment: #"[{"type": "rings"}, {"type": "dip_bench"}]"#)
        ]
        let json = #"{"schemaVersion": 1, "parks": ["# + parks.joined(separator: ",") + "]}"

        let catalog = try ParkSnapshot.decode(Data(json.utf8)).catalog

        #expect(catalog.parks.map(\.generatedName) == ["Park 5"])
    }

    @Test func newerSchemaIsRejected() {
        let future = #"{"schemaVersion": 2, "parks": []}"#
        #expect(throws: ParkDirectoryError.unsupportedSchema(2)) {
            try ParkSnapshot.decode(Data(future.utf8))
        }
    }
}

// MARK: - Directories

struct ParkDirectoryTests {
    /// The real snapshot shipped in the app, written by
    /// `scripts/osm/build_parks_snapshot.py`.
    @Test func bundledSnapshotHoldsValidParks() async throws {
        let directory = BundledParkDirectory(bundle: Bundle(for: AppEnvironment.self))
        let catalog = try await directory.catalog()

        #expect(catalog.parks.count > 200)
        #expect(catalog.dataTimestamp != nil)
        #expect(Set(catalog.parks.map(\.id)).count == catalog.parks.count)
        for park in catalog.parks {
            // Inside Poland's bounding box.
            #expect((49.0...55.0).contains(park.latitude), "\(park.displayName)")
            #expect((14.0...24.2).contains(park.longitude), "\(park.displayName)")
            // A Park: a pull-up bar or parallel bars in the data. The
            // calisthenics tag alone doesn't count (012, owner's addendum).
            #expect(park.equipment.contains { $0.type.isCore }, "\(park.displayName)")
            #expect(!park.generatedName.isEmpty)
            #expect(park.generatedName.hasPrefix(Self.namePrefix(for: park)), "\(park.generatedName)")
            #expect(!park.osmRefs.isEmpty)
            #expect(park.source == .osm && park.verification == .osm && park.status == .published)
        }
    }

    /// The generated-name prefix the pipeline gives (scripts/osm/README.md).
    /// "Street workout" means a bar and bars, never "equipment unknown".
    private static func namePrefix(for park: Park) -> String {
        let types = Set(park.equipment.map(\.type))
        let hasBar = types.contains(.horizontalBar)
        let hasBars = !types.isDisjoint(with: [.parallelBars, .dipBench])
        switch (hasBar, hasBars) {
        case (true, false): return "Drążki"
        case (false, true): return "Poręcze"
        default: return "Street workout"
        }
    }

    /// The decoder drops entries without core equipment, so the check above
    /// alone can't catch a snapshot built with a looser rule. The pipeline
    /// must write only Parks: every entry in the file survives decoding.
    @Test func bundledSnapshotHasNoEntryTheAppDrops() throws {
        let url = try #require(Bundle(for: AppEnvironment.self)
            .url(forResource: BundledParkDirectory.resourceName, withExtension: "json"))
        let data = try Data(contentsOf: url)
        let raw = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let entries = try #require(raw["parks"] as? [Any])

        #expect(try ParkSnapshot.decode(data).parks.count == entries.count)
    }

    @Test func bundledDirectoryReadsOnceAndCaches() async throws {
        let directory = BundledParkDirectory(bundle: Bundle(for: AppEnvironment.self))
        let first = try await directory.catalog()
        let second = try await directory.catalog()
        #expect(first == second)
    }

    @Test func missingSnapshotThrows() async {
        let directory = BundledParkDirectory(url: nil)
        await #expect(throws: ParkDirectoryError.missingSnapshot) {
            try await directory.catalog()
        }
    }

    @Test func inMemoryDirectoryHidesUnpublishedParks() async throws {
        let hidden = ParkFixtures.park(latitude: 52, longitude: 21, status: .pending)
        let directory = InMemoryParkDirectory(parks: [ParkFixtures.mokotow, hidden])
        #expect(try await directory.catalog().parks == [ParkFixtures.mokotow])
    }
}

// MARK: - Model

struct ParkModelTests {
    @Test func equipmentKeysAreOSMValues() {
        let keys = Set(EquipmentType.allCases.map(\.rawValue))
        #expect(keys.isSuperset(of: ["horizontal_bar", "parallel_bars", "dip_bench", "rings", "horizontal_ladder",
                                     "wall_bars", "fitness_pole", "climbing_pole", "push-up", "sit-up"]))
        #expect(Set(EquipmentType.allCases.filter(\.isCore)) == [.horizontalBar, .parallelBars, .dipBench])
    }

    @Test func displayNamePrefersTheProperName() {
        #expect(ParkFixtures.praga.displayName == "Street Workout Skaryszak")
        #expect(ParkFixtures.mokotow.displayName == "Street workout · Park Dreszera")
    }

    @Test(arguments: [
        ([EquipmentType.rings, .parallelBars, .horizontalBar], EquipmentType?.some(.horizontalBar)),
        ([.rings, .dipBench], .some(.dipBench)),
        ([.rings], nil),
        ([], nil)
    ])
    func headlineEquipmentIsTheFirstCoreDevice(equipment: [EquipmentType], expected: EquipmentType?) {
        let park = ParkFixtures.park(latitude: 52, longitude: 21, equipment: equipment)
        #expect(park.headlineEquipment == expected)
        #expect(park.hasCoreEquipment == (expected != nil))
    }

    @Test(arguments: [
        (Locality(city: "Warszawa", district: "Mokotów"), String?.some("Mokotów, Warszawa")),
        (Locality(city: "Szamotuły"), .some("Szamotuły")),
        (Locality(district: "Wola"), .some("Wola")),
        (Locality(), nil)
    ])
    func localityLabel(locality: Locality, expected: String?) {
        #expect(locality.label == expected)
    }

    @Test func verificationLabels() {
        #expect(ParkVerification.osm.label == "Z OSM")
        #expect(ParkVerification.verified.label == "Zweryfikowany")
    }
}

// MARK: - Search and ordering

struct ParkSearchTests {
    @Test(arguments: [
        ("", [ParkFixtures.mokotowID, ParkFixtures.pragaID, ParkFixtures.krakowID, ParkFixtures.lodzID]),
        ("lodz", [ParkFixtures.lodzID]),
        ("KRAKÓW", [ParkFixtures.krakowID]),
        ("krakow jordana", [ParkFixtures.krakowID]),
        ("park dreszera", [ParkFixtures.mokotowID]),
        ("warszawa", [ParkFixtures.mokotowID, ParkFixtures.pragaID]),
        ("skaryszak", [ParkFixtures.pragaID]),
        ("drazki", [ParkFixtures.krakowID]),
        ("warszawa jordana", []),
        ("   ", [ParkFixtures.mokotowID, ParkFixtures.pragaID, ParkFixtures.krakowID, ParkFixtures.lodzID])
    ])
    func matchesEveryWordIgnoringCaseAndDiacritics(query: String, expected: [UUID]) {
        #expect(ParkSearch.matching(ParkFixtures.all, query: query).map(\.id) == expected)
    }

    @Test func ordersByDistanceWhenThePositionIsKnown() throws {
        let ordered = ParkSearch.ordered(ParkFixtures.all, from: ParkFixtures.warsawCentre)

        #expect(ordered.map(\.id) == [ParkFixtures.mokotowID, ParkFixtures.pragaID, ParkFixtures.lodzID, ParkFixtures.krakowID])
        let first = try #require(ordered.first?.meters)
        #expect((2_400...2_800).contains(first))
    }

    @Test func withoutAPositionOrdersByCityAndShowsNoDistance() {
        let ordered = ParkSearch.ordered(ParkFixtures.all, from: nil)

        #expect(ordered.map(\.id) == [ParkFixtures.krakowID, ParkFixtures.lodzID, ParkFixtures.mokotowID, ParkFixtures.pragaID])
        #expect(ordered.allSatisfy { $0.meters == nil })
    }

    @Test func nearest() {
        #expect(ParkSearch.nearest(ParkFixtures.all, to: ParkFixtures.warsawCentre)?.id == ParkFixtures.mokotowID)
        #expect(ParkSearch.nearest([], to: ParkFixtures.warsawCentre) == nil)
    }
}

// MARK: - Formatting

struct ParkFormatTests {
    @Test(arguments: [
        (3.0, "10 m"), (349.0, "350 m"), (994.0, "990 m"), (996.0, "1,0 km"),
        (1_234.0, "1,2 km"), (99_940.0, "99,9 km"), (150_400.0, "150 km")
    ])
    func distance(meters: Double, expected: String) {
        #expect(ParkFormat.distance(meters) == expected)
    }

    @Test(arguments: [(1, "1 Park"), (3, "3 Parki"), (5, "5 Parków"), (12, "12 Parków"), (22, "22 Parki")])
    func parkCount(count: Int, expected: String) {
        #expect(ParkFormat.parkCount(count) == expected)
    }

    @Test func appleMapsLinkCarriesOnlyOurCoordinatesAndName() throws {
        let url = try #require(ParkFormat.appleMapsURL(for: ParkFixtures.mokotow))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.host == "maps.apple.com")
        #expect(components.queryItems?.first { $0.name == "daddr" }?.value == "52.206600,21.018700")
        #expect(components.queryItems?.first { $0.name == "q" }?.value == "Street workout · Park Dreszera")
    }

    @Test func attributionNamesOpenStreetMap() {
        #expect(ParkFormat.attribution == "© Współtwórcy OpenStreetMap")
        #expect(ParkFormat.copyrightURL.absoluteString == "https://www.openstreetmap.org/copyright")
    }
}

// MARK: - Clustering

struct ParkClusteringTests {
    /// Two Parks 300 m apart in central Warsaw, one in Kraków.
    private let near1 = ParkFixtures.park(id: UUID(uuidString: "E0000000-0000-4000-8000-000000000001")!,
                                          latitude: 52.2300, longitude: 21.0100)
    private let near2 = ParkFixtures.park(id: UUID(uuidString: "E0000000-0000-4000-8000-000000000002")!,
                                          latitude: 52.2300, longitude: 21.0144)

    private func region(span: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 52.23, longitude: 21.012),
                           span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
    }

    @Test func zoomedOutCloseParksShareABubble() {
        let clusters = ParkClustering.clusters(for: [near1, near2], in: region(span: 0.5))
        #expect(clusters.count == 1)
        #expect(clusters.first?.parks.count == 2)
    }

    @Test func zoomedInEveryParkIsItsOwnPin() {
        let clusters = ParkClustering.clusters(for: [near1, near2], in: region(span: 0.01))
        #expect(clusters.count == 2)
        #expect(clusters.allSatisfy { $0.isSingle })
    }

    @Test func neighboursAcrossACellEdgeShareOneBubble() {
        // The grid edge at 21.0° E falls between these two; their bubbles
        // would overlap on screen.
        let west = ParkFixtures.park(latitude: 52.23, longitude: 20.999)
        let east = ParkFixtures.park(latitude: 52.23, longitude: 21.001)
        let clusters = ParkClustering.clusters(for: [west, east], in: region(span: 0.5))
        #expect(clusters.count == 1)
        #expect(clusters.first?.parks.count == 2)
    }

    @Test func theSelectedParkNeverJoinsABubble() {
        let clusters = ParkClustering.clusters(for: [near1, near2], in: region(span: 0.5), selectedID: near2.id)
        #expect(clusters.count == 2)
        #expect(clusters.contains { $0.isSingle && $0.parks.first?.id == near2.id })
    }

    @Test func parksFarOutsideTheViewAreSkipped() {
        let clusters = ParkClustering.clusters(for: [near1, ParkFixtures.krakow], in: region(span: 0.05))
        #expect(clusters.flatMap(\.parks).map(\.id) == [near1.id])
    }

    @Test func clusterIDsAreStable() {
        let first = ParkClustering.clusters(for: [near1, near2], in: region(span: 0.5)).map(\.id)
        let again = ParkClustering.clusters(for: [near2, near1], in: region(span: 0.5)).map(\.id)
        #expect(first == again)
    }

    @Test func fittingRegionContainsEveryPark() throws {
        let fitted = try #require(ParkClustering.region(fitting: [near1, near2, ParkFixtures.krakow]))
        for park in [near1, near2, ParkFixtures.krakow] {
            #expect(abs(park.latitude - fitted.center.latitude) <= fitted.span.latitudeDelta / 2)
            #expect(abs(park.longitude - fitted.center.longitude) <= fitted.span.longitudeDelta / 2)
        }
        #expect(ParkClustering.region(fitting: []) == nil)
        #expect(try #require(ParkClustering.region(fitting: [near1])).span.latitudeDelta == 0.004)
    }
}

// MARK: - Equipment labels in exercises

struct ExerciseEquipmentTests {
    @Test func unknownKeysFallBackToTheKey() {
        #expect(ExerciseEquipment.displayName(for: "Pull-up bar") == "Drążek")
        #expect(ExerciseEquipment.displayName(for: "Kettlebell") == "Kettlebell")
    }
}
