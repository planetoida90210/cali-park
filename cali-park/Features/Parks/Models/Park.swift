import CoreLocation
import Foundation

// MARK: - Park
/// A public outdoor place with at least one pull-up bar or set of parallel bars
/// (`GLOSSARY.md`). These are the Park facts from the 012 model
/// (`docs/wayfinder/calipark-1.0/proposals/012-park-model.md`): the layer that
/// is published under ODbL. Community content (reviews, photos) and local data
/// (favorites, distance) never live here.
///
/// Fields the bundled OSM snapshot can't fill yet (`nearbyWater`, dates,
/// `lastConfirmedAt`) arrive with the backend.
struct Park: Identifiable, Hashable, Sendable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var status: ParkStatus
    var verification: ParkVerification
    var source: ParkSource
    /// OSM elements this Park is built from (`n123`, `w456`, `r789`). They can
    /// change between imports, so they are links, never the identity.
    var osmRefs: [String]
    /// A proper name only (from OSM or approved by a Moderator).
    var name: String?
    /// Built from OSM data only, e.g. "Street workout · Park Skaryszewski".
    /// Never from MapKit geocoding.
    var generatedName: String
    var locality: Locality
    var equipment: [ParkEquipment]
    /// OSM `sport=calisthenics`: a Park even when no device is tagged.
    var isCalisthenicsTagged: Bool
    /// Machines (ellipticals, rowers…) stand next to the Park. They are never
    /// listed as Park equipment.
    var hasMachines: Bool
    var surface: ParkSurface?
    var lit: Bool?
    var covered: Bool?
    var access: ParkAccess
    /// OSM `opening_hours` syntax; nil means unknown, not "24 h".
    var openingHours: String?

    var displayName: String { name ?? generatedName }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// The device shown as the map pin glyph: the first core device, so a pin
    /// tells "pull-up bar" or "parallel bars" at a glance.
    var headlineEquipment: EquipmentType? {
        EquipmentType.allCases.first { type in type.isCore && equipment.contains { $0.type == type } }
    }

    init(id: UUID,
         latitude: Double,
         longitude: Double,
         status: ParkStatus = .published,
         verification: ParkVerification = .osm,
         source: ParkSource = .osm,
         osmRefs: [String] = [],
         name: String? = nil,
         generatedName: String,
         locality: Locality = Locality(),
         equipment: [ParkEquipment] = [],
         isCalisthenicsTagged: Bool = false,
         hasMachines: Bool = false,
         surface: ParkSurface? = nil,
         lit: Bool? = nil,
         covered: Bool? = nil,
         access: ParkAccess = .public,
         openingHours: String? = nil) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.verification = verification
        self.source = source
        self.osmRefs = osmRefs
        self.name = name
        self.generatedName = generatedName
        self.locality = locality
        self.equipment = equipment
        self.isCalisthenicsTagged = isCalisthenicsTagged
        self.hasMachines = hasMachines
        self.surface = surface
        self.lit = lit
        self.covered = covered
        self.access = access
        self.openingHours = openingHours
    }
}

// MARK: - Codable
extension Park: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, status, verification, source, osmRefs, name, generatedName
        case locality, equipment, isCalisthenicsTagged, hasMachines, surface, lit, covered, access, openingHours
    }

    /// Lenient where the data may grow: an unknown equipment key or surface is
    /// dropped instead of failing the whole snapshot.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        status = try c.decode(ParkStatus.self, forKey: .status)
        verification = try c.decode(ParkVerification.self, forKey: .verification)
        source = try c.decode(ParkSource.self, forKey: .source)
        osmRefs = try c.decodeIfPresent([String].self, forKey: .osmRefs) ?? []
        name = try c.decodeIfPresent(String.self, forKey: .name)
        generatedName = try c.decode(String.self, forKey: .generatedName)
        locality = try c.decodeIfPresent(Locality.self, forKey: .locality) ?? Locality()
        equipment = try c.decodeIfPresent([LossyEquipment].self, forKey: .equipment)?.compactMap(\.value) ?? []
        isCalisthenicsTagged = try c.decodeIfPresent(Bool.self, forKey: .isCalisthenicsTagged) ?? false
        hasMachines = try c.decodeIfPresent(Bool.self, forKey: .hasMachines) ?? false
        surface = try c.decodeIfPresent(String.self, forKey: .surface).flatMap(ParkSurface.init(rawValue:))
        lit = try c.decodeIfPresent(Bool.self, forKey: .lit)
        covered = try c.decodeIfPresent(Bool.self, forKey: .covered)
        access = try c.decodeIfPresent(String.self, forKey: .access).flatMap(ParkAccess.init(rawValue:)) ?? .public
        openingHours = try c.decodeIfPresent(String.self, forKey: .openingHours)
    }

    private struct LossyEquipment: Decodable {
        let value: ParkEquipment?

        init(from decoder: Decoder) throws {
            value = try? ParkEquipment(from: decoder)
        }
    }
}

// MARK: - Status and provenance
/// Who can see a Park (012 §5). The app only ever shows `published`.
enum ParkStatus: String, Codable, Sendable {
    case candidate, draft, pending, published, rejected, removed
}

/// How much we trust the data; a separate axis from `ParkStatus` (012 §5).
enum ParkVerification: String, Codable, Sendable {
    case osm, community, verified

    /// Badge text on the Park card.
    var label: String {
        switch self {
        case .osm: "Z OSM"
        case .community: "Ze Społeczności"
        case .verified: "Zweryfikowany"
        }
    }
}

enum ParkSource: String, Codable, Sendable {
    case osm, user, team
}

enum ParkAccess: String, Codable, Sendable {
    case `public`, customers, `private`
}

/// OSM `surface` values a Park can have (012 §2).
enum ParkSurface: String, Codable, Sendable, CaseIterable {
    case rubber, tartan, sand, woodchips, grass, ground, gravel, concrete, asphalt
    case artificialTurf = "artificial_turf"
    case pavingStones = "paving_stones"
}

// MARK: - Locality
/// City (gmina/town) and district, computed from OSM administrative boundaries.
struct Locality: Codable, Hashable, Sendable {
    var city: String?
    var district: String?

    init(city: String? = nil, district: String? = nil) {
        self.city = city
        self.district = district
    }

    /// "Mokotów, Warszawa", "Szamotuły", or nil when nothing is known.
    var label: String? {
        switch (district, city) {
        case let (district?, city?): "\(district), \(city)"
        case let (nil, city?): city
        case let (district?, nil): district
        case (nil, nil): nil
        }
    }
}

// MARK: - Equipment
struct ParkEquipment: Codable, Hashable, Sendable {
    var type: EquipmentType
    /// Number of devices, when OSM maps them one by one.
    var count: Int?
    var heights: Set<ParkBarHeight>?

    init(type: EquipmentType, count: Int? = nil, heights: Set<ParkBarHeight>? = nil) {
        self.type = type
        self.count = count
        self.heights = heights
    }
}

/// Bar height without centimetres (012, question 4).
enum ParkBarHeight: String, Codable, Hashable, Sendable, CaseIterable {
    case low, medium, high
}
