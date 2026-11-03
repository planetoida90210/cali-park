#if DEBUG
// PROTOTYPE — throwaway. Ticket: docs/wayfinder/calipark-1.0/tickets/023-park-card.md
// Made-up Parks shaped like the Park model from proposal 012, plus the Community layer
// (photos, reviews) and placeholder weather. Reuses equipment keys, surfaces and the drawn
// sample photos from the Park Submission prototype.

import CoreLocation
import Foundation

// MARK: - Park facts (012 §2)

enum CardVerification: Hashable {
    /// The team was on site.
    case verified(on: Date)
    /// Accepted Submission with an on-site photo, or a Moderator review.
    case community
    /// Imported from OpenStreetMap, nobody from CaliPark checked it.
    case osm

    var title: String {
        switch self {
        case .verified: "Zweryfikowany"
        case .community: "Ze Społeczności"
        case .osm: "Z OSM"
        }
    }

    var symbol: String {
        switch self {
        case .verified: "checkmark.seal.fill"
        case .community: "person.2.fill"
        case .osm: "map"
        }
    }
}

enum CardSource: Hashable {
    case osm, user, team
}

struct CardEquipment: Identifiable, Hashable {
    var type: SubmissionEquipment
    var count: Int?
    var heights: [BarHeight] = []

    var id: String { type.rawValue }
}

struct CardPhoto: Identifiable, Hashable {
    let id: Int
    /// Picks one of the drawn scenes in `SamplePhotoView`.
    let scene: Int
    let author: String
    let takenAt: Date
    var isTeamPhoto = false
    /// The viewer's own upload that a Moderator has not accepted yet.
    var isPendingModeration = false
}

struct CardReview: Identifiable, Hashable {
    let id: Int
    let author: String
    let rating: Int
    let date: Date
    let text: String?
    var isMine = false
}

enum CorrectionKind: String, CaseIterable, Identifiable, Hashable {
    case equipment, gone, location, name, details, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .equipment: "Sprzęt się zmienił"
        case .gone: "Parku już nie ma"
        case .location: "Pinezka jest w złym miejscu"
        case .name: "Nazwa jest zła"
        case .details: "Nawierzchnia, oświetlenie albo dostęp"
        case .other: "Coś innego"
        }
    }

    var symbol: String {
        switch self {
        case .equipment: "figure.strengthtraining.functional"
        case .gone: "xmark.bin"
        case .location: "mappin.and.ellipse"
        case .name: "textformat"
        case .details: "lightbulb"
        case .other: "ellipsis.bubble"
        }
    }
}

/// A correction the viewer sent to the moderation queue (ticket 014). Only its author sees it.
struct CardCorrection: Hashable {
    let kind: CorrectionKind
    let summary: String
    let sentAt: Date
    /// Equipment keys the correction is about, highlighted in the equipment section.
    var affected: Set<SubmissionEquipment> = []
}

struct CardWeatherHour: Identifiable, Hashable {
    let hour: Int
    let symbol: String
    let temperature: Int
    let rainChance: Int

    var id: Int { hour }
}

struct CardWeather: Hashable {
    let symbol: String
    let condition: String
    let temperature: Int
    let feelsLike: Int
    let windKmh: Int
    let hint: String
    let hours: [CardWeatherHour]
}

struct CardPark: Identifiable, Hashable {
    let id: String
    var name: String?
    var generatedName: String
    var locality: String
    var latitude: Double
    var longitude: Double
    var verification: CardVerification
    var source: CardSource
    var osmRefs: [String]
    var equipment: [CardEquipment]
    var isCalisthenicsTagged: Bool
    var hasMachines: Bool
    var surface: SubmissionSurface?
    var lit: Bool?
    var covered: Bool?
    var access: SubmissionAccess
    var openingHours: String?
    var nearbyWater: Bool
    var nearbyToilets: Bool
    var lastConfirmedAt: Date?
    var photos: [CardPhoto]
    var reviews: [CardReview]
    var correction: CardCorrection?
    var weather: CardWeather

    var displayName: String { name ?? generatedName }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var distance: CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: ParkCardSampleData.userLocation.latitude, longitude: ParkCardSampleData.userLocation.longitude))
    }

    var hasOSMData: Bool { source == .osm || !osmRefs.isEmpty }

    var averageRating: Double? {
        guard !reviews.isEmpty else { return nil }
        return Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
    }

    func ratingShare(of stars: Int) -> Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(reviews.filter { $0.rating == stars }.count) / Double(reviews.count)
    }

    /// Pin glyph: the rarest piece of equipment, or a question mark when equipment is unknown.
    var pinSymbol: String {
        let types = equipment.map(\.type)
        if types.contains(.rings) { return SubmissionEquipment.rings.symbol }
        if types.contains(.parallelBars) { return SubmissionEquipment.parallelBars.symbol }
        if let first = types.first { return first.symbol }
        return "questionmark"
    }

    /// Flag needs a vertical pole (012 §3).
    var supportsFlag: Bool {
        equipment.contains { [.fitnessPole, .climbingPole, .wallBars].contains($0.type) }
    }
}

// MARK: - Sample data

enum ParkCardSampleData {
    /// Same fake "you are here" point as the map-look prototype (near the Palace of Culture).
    static let userLocation = MapLookSampleData.userLocation

    static let now = SubmissionSampleData.now
    static let nickname = SubmissionSampleData.nickname

    static func daysAgo(_ days: Double) -> Date { SubmissionSampleData.daysAgo(days) }

    private static let cloudyAfternoon = CardWeather(
        symbol: "cloud.sun.fill", condition: "Przejaśnienia", temperature: 9, feelsLike: 6, windKmh: 14,
        hint: "Sucho do 17:00, potem deszcz",
        hours: [
            CardWeatherHour(hour: 13, symbol: "cloud.sun.fill", temperature: 9, rainChance: 5),
            CardWeatherHour(hour: 14, symbol: "cloud.sun.fill", temperature: 10, rainChance: 5),
            CardWeatherHour(hour: 15, symbol: "cloud.fill", temperature: 10, rainChance: 10),
            CardWeatherHour(hour: 16, symbol: "cloud.fill", temperature: 9, rainChance: 20),
            CardWeatherHour(hour: 17, symbol: "cloud.drizzle.fill", temperature: 8, rainChance: 60),
            CardWeatherHour(hour: 18, symbol: "cloud.rain.fill", temperature: 7, rainChance: 80),
        ]
    )

    static let rich = CardPark(
        id: "rich",
        name: "Street Workout Skaryszak",
        generatedName: "Street workout · Park Skaryszewski",
        locality: "Praga-Południe, Warszawa",
        latitude: 52.2422, longitude: 21.0592,
        verification: .verified(on: daysAgo(23)),
        source: .osm,
        osmRefs: ["w412883091"],
        equipment: [
            CardEquipment(type: .horizontalBar, count: 4, heights: [.low, .medium, .high]),
            CardEquipment(type: .parallelBars, count: 2),
            CardEquipment(type: .rings, count: 2),
            CardEquipment(type: .wallBars, count: 1),
            CardEquipment(type: .fitnessPole, count: 1),
            CardEquipment(type: .horizontalLadder, count: 1),
        ],
        isCalisthenicsTagged: true,
        hasMachines: true,
        surface: .rubber, lit: true, covered: false, access: .open,
        openingHours: nil,
        nearbyWater: true, nearbyToilets: false,
        lastConfirmedAt: daysAgo(23),
        photos: [
            CardPhoto(id: 1, scene: 0, author: "Ekipa CaliPark", takenAt: daysAgo(23), isTeamPhoto: true),
            CardPhoto(id: 2, scene: 3, author: "Ekipa CaliPark", takenAt: daysAgo(23), isTeamPhoto: true),
            CardPhoto(id: 3, scene: 1, author: "ola_planche", takenAt: daysAgo(41)),
            CardPhoto(id: 4, scene: 2, author: "marek_muscleup", takenAt: daysAgo(77)),
            CardPhoto(id: 5, scene: 0, author: "kasia.kalistenika", takenAt: daysAgo(120)),
        ],
        reviews: [
            CardReview(id: 1, author: "ola_planche", rating: 5, date: daysAgo(3), text: "Najlepsze kółka po tej stronie Wisły. Wysoki drążek naprawdę wysoki, muscle-upy bez stresu."),
            CardReview(id: 2, author: "marek_muscleup", rating: 5, date: daysAgo(12), text: "Gumowa nawierzchnia, lampy do 22. W tygodniu wieczorem sporo ludzi, ale da się dzielić."),
            CardReview(id: 3, author: "tomek_z_pragi", rating: 4, date: daysAgo(30), text: "Poręcze trochę za szerokie na dipy dla niższych osób. Poza tym super."),
            CardReview(id: 4, author: "anka_hs", rating: 5, date: daysAgo(48), text: nil),
            CardReview(id: 5, author: "bartek.front", rating: 4, date: daysAgo(66), text: "Słup do flagi jest, ale lekko się rusza. Zgłoszone."),
            CardReview(id: 6, author: "julka_l_sit", rating: 3, date: daysAgo(90), text: "Po deszczu długo stoi woda pod drążkami."),
        ],
        correction: nil,
        weather: cloudyAfternoon
    )

    static let community = CardPark(
        id: "community",
        name: nil,
        generatedName: "Street workout · Pole Mokotowskie",
        locality: "Mokotów, Warszawa",
        latitude: 52.2121, longitude: 21.0063,
        verification: .community,
        source: .user,
        osmRefs: [],
        equipment: [
            CardEquipment(type: .horizontalBar, count: 2, heights: [.medium, .high]),
            CardEquipment(type: .parallelBars, count: 1),
            CardEquipment(type: .rings),
        ],
        isCalisthenicsTagged: false,
        hasMachines: false,
        surface: .sand, lit: false, covered: false, access: .open,
        openingHours: nil,
        nearbyWater: false, nearbyToilets: true,
        lastConfirmedAt: daysAgo(8),
        photos: [
            CardPhoto(id: 11, scene: 1, author: "kuba_na_drazku", takenAt: daysAgo(9)),
            CardPhoto(id: 12, scene: 2, author: "kuba_na_drazku", takenAt: daysAgo(9)),
        ],
        reviews: [
            CardReview(id: 11, author: "ewa_biega", rating: 4, date: daysAgo(5), text: "Fajne miejsce po bieganiu po Polu. Piasek pod drążkami."),
            CardReview(id: 12, author: "piotr_dips", rating: 4, date: daysAgo(7), text: nil),
        ],
        correction: nil,
        weather: cloudyAfternoon
    )

    static let osmOnly = CardPark(
        id: "osm",
        name: nil,
        generatedName: "Street workout · ul. Kasprzaka",
        locality: "Wola, Warszawa",
        latitude: 52.2290, longitude: 20.9700,
        verification: .osm,
        source: .osm,
        osmRefs: ["n10293847561"],
        equipment: [],
        isCalisthenicsTagged: true,
        hasMachines: false,
        surface: nil, lit: nil, covered: nil, access: .open,
        openingHours: nil,
        nearbyWater: false, nearbyToilets: false,
        lastConfirmedAt: nil,
        photos: [],
        reviews: [],
        correction: nil,
        weather: cloudyAfternoon
    )

    static let pendingCorrection = CardPark(
        id: "pending",
        name: "Poręcze przy Skarpie",
        generatedName: "Street workout · Powiśle",
        locality: "Powiśle, Warszawa",
        latitude: 52.2367, longitude: 21.0236,
        verification: .verified(on: daysAgo(160)),
        source: .team,
        osmRefs: [],
        equipment: [
            CardEquipment(type: .horizontalBar, count: 3, heights: [.low, .medium, .high]),
            CardEquipment(type: .parallelBars, count: 2),
            CardEquipment(type: .dipBench, count: 1),
        ],
        isCalisthenicsTagged: false,
        hasMachines: false,
        surface: .pavingStones, lit: true, covered: false, access: .open,
        openingHours: nil,
        nearbyWater: true, nearbyToilets: true,
        lastConfirmedAt: daysAgo(160),
        photos: [
            CardPhoto(id: 21, scene: 3, author: "Ekipa CaliPark", takenAt: daysAgo(160), isTeamPhoto: true),
            CardPhoto(id: 22, scene: 2, author: "wisla_workout", takenAt: daysAgo(200)),
        ],
        reviews: [
            CardReview(id: 21, author: "wisla_workout", rating: 4, date: daysAgo(20), text: "Wysokiego drążka już nie ma, zostały słupki. Reszta OK."),
            CardReview(id: 22, author: "ania_pompki", rating: 5, date: daysAgo(150), text: "Ładny widok na Wisłę, oświetlone wieczorem."),
            CardReview(id: 23, author: "grzesiek_bw", rating: 4, date: daysAgo(170), text: nil),
        ],
        correction: CardCorrection(
            kind: .equipment,
            summary: "Wysoki drążek zdemontowany, zostały 2 drążki: niski i średni",
            sentAt: daysAgo(2),
            affected: [.horizontalBar]
        ),
        weather: cloudyAfternoon
    )

    static let parks: [CardPark] = [rich, community, osmOnly, pendingCorrection]
}

// MARK: - Formatting

enum ParkCardFormat {
    private static let polish = Locale(identifier: "pl_PL")

    static func rating(_ value: Double) -> String { MapLookFormat.rating(value) }

    /// "1 opinia", "3 opinie", "6 opinii".
    static func reviews(_ count: Int) -> String {
        "\(count) \(PolishPlural.form(for: count, one: "opinia", few: "opinie", many: "opinii"))"
    }

    static func photos(_ count: Int) -> String { SubmissionFormat.photos(count) }

    /// "4 listopada 2026".
    static func day(_ date: Date) -> String {
        var style = Date.FormatStyle.dateTime.day().month(.wide).year()
        style.locale = polish
        style.timeZone = TimeZone(identifier: "Europe/Warsaw") ?? .gmt
        return date.formatted(style)
    }

    /// "listopad 2026", used as "Potwierdzone: listopad 2026".
    static func month(_ date: Date) -> String {
        var style = Date.FormatStyle.dateTime.month(.wide).year()
        style.locale = polish
        style.timeZone = TimeZone(identifier: "Europe/Warsaw") ?? .gmt
        return date.formatted(style)
    }

    /// "dziś", "wczoraj", "3 dni temu", "2 tyg. temu", "4 mies. temu".
    static func relative(_ date: Date) -> String {
        let days = Int((ParkCardSampleData.now.timeIntervalSince(date) / 86_400).rounded(.down))
        switch days {
        case ..<1: return "dziś"
        case 1: return "wczoraj"
        case 2..<14: return "\(days) dni temu"
        case 14..<60: return "\(days / 7) tyg. temu"
        default: return "\(days / 30) mies. temu"
        }
    }

    /// "×3" for a known count.
    static func count(_ value: Int?) -> String? {
        value.map { "×\($0)" }
    }
}
#endif
