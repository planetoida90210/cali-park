import Foundation

// MARK: - ParkCatalog
/// Every published Park plus where the data comes from.
nonisolated struct ParkCatalog: Hashable, Sendable {
    var parks: [Park]
    /// When the OSM data was taken (Overpass `timestamp_osm_base`).
    var dataTimestamp: Date?

    init(parks: [Park], dataTimestamp: Date? = nil) {
        self.parks = parks
        self.dataTimestamp = dataTimestamp
    }
}

// MARK: - ParkDirectory
/// Read-only source of Parks. Today it is the OSM snapshot bundled in the app;
/// the backend replaces it later behind the same protocol.
nonisolated protocol ParkDirectory: Sendable {
    /// Published Parks only. Throws when the data can't be read; callers show
    /// an error instead of an empty map.
    func catalog() async throws -> ParkCatalog
}

nonisolated enum ParkDirectoryError: Error, Equatable {
    case missingSnapshot
    case unsupportedSchema(Int)
}

// MARK: - ParkSnapshot
/// On-disk format written by `scripts/osm/build_parks_snapshot.py`. The same
/// file is the public ODbL dump in `data/`.
nonisolated struct ParkSnapshot: Decodable, Sendable {
    static let supportedSchemaVersion = 1

    var schemaVersion: Int
    var osmDataTimestamp: Date?
    var parks: [Park]

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, osmDataTimestamp, parks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion <= Self.supportedSchemaVersion else {
            throw ParkDirectoryError.unsupportedSchema(schemaVersion)
        }
        osmDataTimestamp = try c.decodeIfPresent(Date.self, forKey: .osmDataTimestamp)
        // Like an unknown equipment key, an entry without core equipment
        // (e.g. its only bar has a key this version doesn't know) is dropped,
        // not shown with an empty equipment list.
        parks = try c.decode([Park].self, forKey: .parks).filter(\.hasCoreEquipment)
    }

    static func decode(_ data: Data) throws -> ParkSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ParkSnapshot.self, from: data)
    }

    var catalog: ParkCatalog {
        ParkCatalog(parks: parks.filter { $0.status == .published }, dataTimestamp: osmDataTimestamp)
    }
}

// MARK: - BundledParkDirectory
/// Reads the OSM snapshot shipped in the app bundle once and keeps it.
actor BundledParkDirectory: ParkDirectory {
    static let resourceName = "parks-osm-pl"

    private let url: URL?
    private var cached: ParkCatalog?

    init(url: URL?) {
        self.url = url
    }

    init(bundle: Bundle = .main) {
        self.init(url: bundle.url(forResource: Self.resourceName, withExtension: "json"))
    }

    func catalog() async throws -> ParkCatalog {
        if let cached { return cached }
        guard let url else { throw ParkDirectoryError.missingSnapshot }
        let catalog = try ParkSnapshot.decode(Data(contentsOf: url)).catalog
        cached = catalog
        return catalog
    }
}
