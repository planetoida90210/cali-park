import CoreLocation
import Foundation

// MARK: - ParkFormat
/// Polish text and links for Parks.
nonisolated enum ParkFormat {
    private static let polish = Locale(identifier: "pl_PL")

    /// Required OSM credit (ODbL, OSMF attribution guidelines).
    static let attribution = String(localized: "© Współtwórcy OpenStreetMap")
    static let copyrightURL = URL(string: "https://www.openstreetmap.org/copyright")!

    /// "350 m" under a kilometre, "1,2 km" under 100 km, "123 km" above.
    static func distance(_ meters: CLLocationDistance) -> String {
        let tens = Int((meters / 10).rounded()) * 10
        if tens < 1000 {
            return String(localized: "\(max(10, tens)) m")
        }
        let km = meters / 1000
        if km >= 100 {
            return String(localized: "\(Int(km.rounded())) km")
        }
        return String(localized: "\(km.formatted(.number.precision(.fractionLength(1)).locale(polish))) km")
    }

    /// "1 Park", "3 Parki", "25 Parków".
    static func parkCount(_ count: Int) -> String {
        "\(count) \(PolishPlural.form(for: count, one: "Park", few: "Parki", many: "Parków"))"
    }

    /// "Dane OSM z 3 lis 2026".
    static func dataDate(_ date: Date) -> String {
        String(localized: "Dane OSM z \(date.formatted(.dateTime.day().month(.abbreviated).year().locale(polish)))")
    }

    /// Directions to the Park in Apple Maps. Only our own coordinates go out;
    /// nothing comes back from MapKit into the Park data.
    static func appleMapsURL(for park: Park) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.path = "/"
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(coordinate(park.latitude)),\(coordinate(park.longitude))"),
            URLQueryItem(name: "q", value: park.displayName)
        ]
        return components.url
    }

    /// The OSM page of the first element the Park is built from (`n123` →
    /// `https://www.openstreetmap.org/node/123`), or nil without a valid ref.
    static func osmURL(for park: Park) -> URL? {
        guard let ref = park.osmRefs.first, let kind = ref.first else { return nil }
        let number = ref.dropFirst()
        guard !number.isEmpty, number.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        let type: String
        switch kind {
        case "n": type = "node"
        case "w": type = "way"
        case "r": type = "relation"
        default: return nil
        }
        return URL(string: "https://www.openstreetmap.org/\(type)/\(number)")
    }

    // MARK: Card

    /// "Mokotów, Warszawa · 1,2 km"; the distance only when it is known.
    static func subtitle(for park: Park, distance: CLLocationDistance?) -> String? {
        let parts = [park.locality.label, distance.map(Self.distance)].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The same for VoiceOver: "Mokotów, Warszawa, 1,2 km od Ciebie".
    static func subtitleAccessibility(for park: Park, distance: CLLocationDistance?) -> String? {
        let parts = [park.locality.label, distance.map { String(localized: "\(Self.distance($0)) od Ciebie") }].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// "× 7", or nil when OSM doesn't say how many there are.
    static func count(_ item: ParkEquipment) -> String? {
        item.count.map { "× \($0)" }
    }

    /// "niski, wysoki" in low-to-high order, or nil when heights are unknown.
    static func heights(_ item: ParkEquipment) -> String? {
        guard let heights = item.heights, !heights.isEmpty else { return nil }
        return ParkBarHeight.allCases.filter(heights.contains).map(\.title).joined(separator: ", ")
    }

    /// "Drążek, 7 sztuk, wysokości: niski, wysoki" for VoiceOver.
    static func equipmentAccessibility(_ item: ParkEquipment) -> String {
        var parts = [item.type.title]
        if let count = item.count {
            parts.append("\(count) \(PolishPlural.form(for: count, one: "sztuka", few: "sztuki", many: "sztuk"))")
        }
        if let heights = heights(item) {
            parts.append(String(localized: "wysokości: \(heights)"))
        }
        return parts.joined(separator: ", ")
    }

    /// "Sprzęt: Drążek, Poręcze i 2 inne" for the compact card's glyphs.
    static func equipmentSummary(_ equipment: [ParkEquipment], shown limit: Int) -> String {
        let names = equipment.prefix(limit).map(\.type.title).joined(separator: ", ")
        let rest = equipment.count - min(limit, equipment.count)
        guard rest > 0 else { return String(localized: "Sprzęt: \(names)") }
        let others = PolishPlural.form(for: rest, one: "inny", few: "inne", many: "innych")
        return String(localized: "Sprzęt: \(names) i \(rest) \(others)")
    }

    /// The equipment ladders for the flag need a vertical pole or wall bars
    /// (012 §3).
    static func supportsFlag(_ park: Park) -> Bool {
        park.equipment.contains { [.fitnessPole, .climbingPole, .wallBars].contains($0.type) }
    }

    /// "Szczegóły" rows, always the same rows in the same order; `value` is nil
    /// when OSM doesn't say ("Brak danych"), never a guess.
    static func details(for park: Park) -> [ParkDetail] {
        [
            ParkDetail(id: .surface, value: park.surface?.title),
            ParkDetail(id: .lighting, value: park.lit.map(yesNo)),
            ParkDetail(id: .roof, value: park.covered.map(yesNo)),
            ParkDetail(id: .access, value: park.access.title),
            ParkDetail(id: .openingHours, value: park.openingHours.map(ParkOpeningHours.text(for:))),
            // OSM can only say machines are there, never that they are not.
            ParkDetail(id: .machines, value: park.hasMachines ? String(localized: "Tak, obok Parku") : nil)
        ]
    }

    /// Text for a missing detail.
    static let unknownDetail = String(localized: "Brak danych")

    private static func yesNo(_ value: Bool) -> String {
        value ? String(localized: "Tak") : String(localized: "Nie")
    }

    /// "52.229700": a dot and no grouping whatever the device locale is.
    private static func coordinate(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(6)).grouping(.never).locale(Locale(identifier: "en_US_POSIX")))
    }
}

// MARK: - Polish names
nonisolated extension ParkSurface {
    var title: String {
        switch self {
        case .rubber: String(localized: "Gumowa")
        case .tartan: String(localized: "Tartan")
        case .sand: String(localized: "Piasek")
        case .woodchips: String(localized: "Zrębki")
        case .grass: String(localized: "Trawa")
        case .ground: String(localized: "Ziemia")
        case .gravel: String(localized: "Żwir")
        case .concrete: String(localized: "Beton")
        case .asphalt: String(localized: "Asfalt")
        case .artificialTurf: String(localized: "Sztuczna trawa")
        case .pavingStones: String(localized: "Kostka brukowa")
        }
    }
}

nonisolated extension ParkAccess {
    var title: String {
        switch self {
        case .public: String(localized: "Dla wszystkich")
        case .customers: String(localized: "Tylko dla klientów")
        case .private: String(localized: "Prywatny")
        }
    }
}

nonisolated extension ParkBarHeight {
    var title: String {
        switch self {
        case .low: String(localized: "niski")
        case .medium: String(localized: "średni")
        case .high: String(localized: "wysoki")
        }
    }
}

nonisolated extension ParkVerification {
    /// What the badge means, for VoiceOver.
    var accessibilityLabel: String {
        switch self {
        case .osm: String(localized: "Dane z OpenStreetMap, niesprawdzone przez CaliPark")
        case .community: String(localized: "Dodany przez Społeczność")
        case .verified: String(localized: "Zweryfikowany przez ekipę CaliPark")
        }
    }

    /// "Skąd te dane" explanation on the full card.
    var explanation: String {
        switch self {
        case .osm:
            String(
                localized:
                    "Dane pochodzą z OpenStreetMap, otwartej mapy tworzonej przez wolontariuszy. Nikt z CaliPark jeszcze ich nie sprawdził na miejscu, więc mogą być nieaktualne."
            )
        case .community:
            String(
                localized:
                    "Park dodała osoba ze Społeczności, ze zdjęciem z miejsca. Moderator sprawdził Zgłoszenie, ale ekipa CaliPark jeszcze tu nie była."
            )
        case .verified:
            String(localized: "Ekipa CaliPark była tu i sprawdziła sprzęt na miejscu.")
        }
    }
}
