#if DEBUG
// PROTOTYPE — throwaway. Ticket: docs/wayfinder/calipark-1.0/tickets/013-submission-form.md
// Made-up data and the Park model bits from proposal 012 that the Submission form needs.

import CoreLocation
import Foundation

// MARK: - Equipment (keys = OSM `fitness_station`, proposal 012 §3)

enum SubmissionEquipment: String, CaseIterable, Identifiable, Hashable {
    case horizontalBar = "horizontal_bar"
    case parallelBars = "parallel_bars"
    case dipBench = "dip_bench"
    case rings
    case horizontalLadder = "horizontal_ladder"
    case wallBars = "wall_bars"
    case fitnessPole = "fitness_pole"
    case climbingPole = "climbing_pole"
    case captainsChair = "captains_chair"
    case pushUp = "push-up"
    case sitUp = "sit-up"
    case stretchBars = "stretch_bars"
    case box
    case balanceBeam = "balance_beam"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .horizontalBar: "Drążek"
        case .parallelBars: "Poręcze"
        case .dipBench: "Poręcze do dipów"
        case .rings: "Kółka"
        case .horizontalLadder: "Drabinka pozioma"
        case .wallBars: "Drabinki gimnastyczne"
        case .fitnessPole: "Pionowy drążek"
        case .climbingPole: "Słup do wspinania"
        case .captainsChair: "Poręcze z oparciem"
        case .pushUp: "Niskie drążki do pompek"
        case .sitUp: "Ławka do brzuszków"
        case .stretchBars: "Drążki do rozciągania"
        case .box: "Skrzynia do skoków"
        case .balanceBeam: "Równoważnia"
        }
    }

    /// Temporary SF Symbols, like in the map-look prototype.
    var symbol: String {
        switch self {
        case .horizontalBar: "figure.climbing"
        case .parallelBars: "figure.strengthtraining.functional"
        case .dipBench: "equal.square"
        case .rings: "figure.gymnastics"
        case .horizontalLadder: "rectangle.split.3x1"
        case .wallBars: "stairs"
        case .fitnessPole: "flag.fill"
        case .climbingPole: "arrow.up.to.line"
        case .captainsChair: "chair.fill"
        case .pushUp: "figure.strengthtraining.traditional"
        case .sitUp: "figure.core.training"
        case .stretchBars: "figure.flexibility"
        case .box: "shippingbox.fill"
        case .balanceBeam: "figure.step.training"
        }
    }

    /// "Core" equipment makes a place a Park on its own (owner, ticket 012: a bar or parallel bars).
    var isCore: Bool {
        switch self {
        case .horizontalBar, .parallelBars, .dipBench: true
        default: false
        }
    }

    static let core = allCases.filter(\.isCore)
    static let extra = allCases.filter { !$0.isCore }
}

enum BarHeight: String, CaseIterable, Identifiable, Hashable {
    case low, medium, high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Niski"
        case .medium: "Średni"
        case .high: "Wysoki"
        }
    }
}

/// Optional facts from proposal 012 §2.
enum SubmissionSurface: String, CaseIterable, Identifiable, Hashable {
    case rubber, tartan, artificialTurf = "artificial_turf", sand, woodchips, grass, ground, gravel
    case pavingStones = "paving_stones", concrete, asphalt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rubber: "Guma"
        case .tartan: "Tartan"
        case .artificialTurf: "Sztuczna trawa"
        case .sand: "Piasek"
        case .woodchips: "Zrębki"
        case .grass: "Trawa"
        case .ground: "Ziemia"
        case .gravel: "Żwir"
        case .pavingStones: "Kostka"
        case .concrete: "Beton"
        case .asphalt: "Asfalt"
        }
    }
}

enum TriState: String, CaseIterable, Identifiable, Hashable {
    case yes, no, unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes: "Tak"
        case .no: "Nie"
        case .unknown: "Nie wiem"
        }
    }
}

enum SubmissionAccess: String, CaseIterable, Identifiable, Hashable {
    case open = "public"
    case customers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .open: "Dla wszystkich"
        case .customers: "Tylko dla klientów"
        }
    }
}

// MARK: - Draft

struct SubmissionDraft {
    var coordinate: CLLocationCoordinate2D
    var equipment: Set<SubmissionEquipment> = []
    var barCount: Int?
    var barHeights: Set<BarHeight> = []
    var parallelBarsCount: Int?
    var hasMachines = false
    var photos: [Int] = []
    var plaqueName = ""
    var surface: SubmissionSurface?
    var lit: TriState = .unknown
    var covered: TriState = .unknown
    var access: SubmissionAccess = .open

    static let maxPhotos = 5

    var hasCoreEquipment: Bool { equipment.contains { $0.isCore } }
    var hasPhoto: Bool { !photos.isEmpty }
    var canSend: Bool { hasCoreEquipment && hasPhoto }

    var generatedName: String {
        SubmissionNaming.generatedName(at: coordinate, equipment: equipment)
    }

    var plaqueNameProblem: String? { SubmissionNaming.problem(with: plaqueName) }

    var trimmedPlaqueName: String? {
        let trimmed = plaqueName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || plaqueNameProblem != nil ? nil : trimmed
    }

    /// Short list of what blocks sending, in form order.
    var missing: [String] {
        var result: [String] = []
        if !hasCoreEquipment { result.append("drążka albo poręczy") }
        if !hasPhoto { result.append("zdjęcia z miejsca") }
        return result
    }

    var sortedEquipment: [SubmissionEquipment] {
        SubmissionEquipment.allCases.filter(equipment.contains)
    }

    /// Optional facts the author filled in, for the summary.
    var filledDetails: [(label: String, value: String)] {
        var rows: [(String, String)] = []
        if let barCount { rows.append(("Drążki", "\(barCount == 4 ? "4 lub więcej" : String(barCount)) szt.")) }
        if !barHeights.isEmpty {
            rows.append(("Wysokość drążków", BarHeight.allCases.filter(barHeights.contains).map(\.title).joined(separator: ", ")))
        }
        if let parallelBarsCount { rows.append(("Poręcze", "\(parallelBarsCount == 4 ? "4 lub więcej" : String(parallelBarsCount)) szt.")) }
        if hasMachines { rows.append(("Obok", "maszyny (np. orbitrek)")) }
        if let surface { rows.append(("Nawierzchnia", surface.title)) }
        if lit != .unknown { rows.append(("Oświetlenie", lit.title)) }
        if covered != .unknown { rows.append(("Zadaszenie", covered.title)) }
        if access != .open { rows.append(("Dostęp", access.title)) }
        return rows
    }
}

// MARK: - Naming (proposal 012 §4)

/// Stand-in for the backend's name generator, which uses OSM data only.
/// The areas below are hand-placed circles, not OSM polygons.
enum SubmissionNaming {
    private struct NamedArea {
        let label: String
        let latitude: Double
        let longitude: Double
        let radius: CLLocationDistance
    }

    private static let areas: [NamedArea] = [
        NamedArea(label: "Park Skaryszewski", latitude: 52.2425, longitude: 21.0560, radius: 650),
        NamedArea(label: "Pole Mokotowskie", latitude: 52.2125, longitude: 21.0000, radius: 700),
        NamedArea(label: "Park Ujazdowski", latitude: 52.2205, longitude: 21.0275, radius: 250),
        NamedArea(label: "Ogród Saski", latitude: 52.2405, longitude: 21.0080, radius: 300),
        NamedArea(label: "przy SP 12", latitude: 52.2290, longitude: 20.9890, radius: 120),
        NamedArea(label: "ul. Kasprzaka", latitude: 52.2290, longitude: 20.9700, radius: 400),
    ]

    static func generatedName(at coordinate: CLLocationCoordinate2D, equipment: Set<SubmissionEquipment>) -> String {
        "\(prefix(for: equipment)) · \(place(at: coordinate))"
    }

    /// "Street workout" with a bar and bars, otherwise the one that is there.
    static func prefix(for equipment: Set<SubmissionEquipment>) -> String {
        let hasBar = equipment.contains(.horizontalBar)
        let hasBars = equipment.contains(.parallelBars) || equipment.contains(.dipBench)
        switch (hasBar, hasBars) {
        case (true, false): return "Drążki"
        case (false, true): return "Poręcze"
        default: return "Street workout"
        }
    }

    static func place(at coordinate: CLLocationCoordinate2D) -> String {
        let point = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let area = areas.first(where: {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: point) <= $0.radius
        }) {
            return area.label
        }
        let nearest = MapLookSampleData.parks.min {
            $0.distance(from: coordinate) < $1.distance(from: coordinate)
        }
        return nearest?.district ?? "Warszawa"
    }

    /// Client-side check from 012 §4. Returns nil for an empty or valid name.
    static func problem(with raw: String) -> String? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        if name.count < 3 { return "Za krótka. Nazwa ma od 3 do 40 znaków." }
        if name.count > 40 { return "Za długa. Nazwa ma od 3 do 40 znaków." }
        if name.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation }) {
            return "Bez emoji. Wpisz nazwę tak, jak jest na tabliczce."
        }
        let lower = name.lowercased()
        if lower.contains("http") || lower.contains("www.") || lower.contains(".pl") || lower.contains(".com") {
            return "Bez linków."
        }
        if name.filter(\.isNumber).count >= 7 { return "Bez numerów telefonu." }
        let letters = name.filter(\.isLetter)
        if letters.count >= 4 && letters == letters.uppercased() {
            return "Bez CAPS LOCKA. Wielka litera tylko na początku słów."
        }
        return nil
    }
}

// MARK: - Submissions visible to the author (012 §5)

enum SubmissionStatus: Hashable {
    case draft
    case pending
    case published
    case rejected(reason: String, explanation: String)
    case removed(reason: String, explanation: String)

    var title: String {
        switch self {
        case .draft: "Szkic"
        case .pending: "Czeka na moderację"
        case .published: "Opublikowany"
        case .rejected: "Odrzucone"
        case .removed: "Usunięty z mapy"
        }
    }

    var symbol: String {
        switch self {
        case .draft: "pencil"
        case .pending: "clock"
        case .published: "checkmark.seal.fill"
        case .rejected: "xmark.octagon.fill"
        case .removed: "minus.circle.fill"
        }
    }
}

struct PrototypeSubmission: Identifiable, Hashable {
    let id: Int
    var name: String
    var proposedName: String?
    var equipment: [SubmissionEquipment]
    var photoCount: Int
    var status: SubmissionStatus
    /// When it was created on the phone (draft) or sent.
    var sentAt: Date
    var decidedAt: Date?
}

enum SubmissionSampleData {
    /// Fake "you are here" point inside Park Skaryszewski, about 460 m from the nearest sample Park.
    static let userLocation = CLLocationCoordinate2D(latitude: 52.2405, longitude: 21.0530)

    /// About 25 m from the sample Park "Street Workout Skaryszak", used to demo the duplicate warning.
    static let duplicateDemoLocation = CLLocationCoordinate2D(latitude: 52.24232, longitude: 21.05885)

    /// The duplicate radius from the brief.
    static let duplicateRadius: CLLocationDistance = 50

    static let nickname = "kuba_na_drazku"

    /// Fixed "today" for the prototype: 2026-11-04 12:00 UTC.
    static let now = Date(timeIntervalSince1970: 1_793_793_600)

    static func daysAgo(_ days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }

    static func nearbyPark(to coordinate: CLLocationCoordinate2D) -> (park: MapLookPark, distance: CLLocationDistance)? {
        MapLookSampleData.parks
            .map { ($0, $0.distance(from: coordinate)) }
            .filter { $0.1 <= duplicateRadius }
            .min { $0.1 < $1.1 }
            .map { (park: $0.0, distance: $0.1) }
    }

    static let submissions: [PrototypeSubmission] = [
        PrototypeSubmission(
            id: 1, name: "Drążki · ul. Kasprzaka", proposedName: nil,
            equipment: [.horizontalBar, .wallBars], photoCount: 2,
            status: .pending, sentAt: daysAgo(2)
        ),
        PrototypeSubmission(
            id: 2, name: "Street workout · Pole Mokotowskie", proposedName: nil,
            equipment: [.horizontalBar, .parallelBars, .rings], photoCount: 3,
            status: .published, sentAt: daysAgo(9), decidedAt: daysAgo(8)
        ),
        PrototypeSubmission(
            id: 3, name: "Street workout · przy SP 12", proposedName: "Siłownia Zdrowia",
            equipment: [.horizontalBar, .parallelBars], photoCount: 1,
            status: .rejected(
                reason: "To nie jest Park",
                explanation: "Na zdjęciu widać tylko maszyny: orbitrek i wioślarz. Nie ma drążka ani poręczy, a Park musi mieć jedno z nich."
            ),
            sentAt: daysAgo(16), decidedAt: daysAgo(15)
        ),
        PrototypeSubmission(
            id: 4, name: "Street workout · Muranów", proposedName: nil,
            equipment: [.horizontalBar, .parallelBars], photoCount: 2,
            status: .rejected(
                reason: "Ten Park już jest na mapie",
                explanation: "To ten sam Park co „Strefa Ruchu Muranów”, 30 m dalej. Twoje zdjęcia dodaliśmy do tamtego Parku."
            ),
            sentAt: daysAgo(30), decidedAt: daysAgo(29)
        ),
        PrototypeSubmission(
            id: 5, name: "Drążki · Ochota", proposedName: nil,
            equipment: [.horizontalBar], photoCount: 1,
            status: .removed(
                reason: "Park już nie istnieje",
                explanation: "Ktoś zgłosił, że drążki zdemontowano przy remoncie skweru. Ekipa potwierdziła to na miejscu."
            ),
            sentAt: daysAgo(120), decidedAt: daysAgo(3)
        ),
        PrototypeSubmission(
            id: 6, name: "Street workout · Ogród Saski", proposedName: nil,
            equipment: [.horizontalBar], photoCount: 0,
            status: .draft, sentAt: daysAgo(1)
        ),
    ]
}

// MARK: - Formatting

enum SubmissionFormat {
    private static let polish = Locale(identifier: "pl_PL")

    /// "4 listopada".
    static func day(_ date: Date) -> String {
        var style = Date.FormatStyle.dateTime.day().month(.wide)
        style.locale = polish
        style.timeZone = TimeZone(identifier: "Europe/Warsaw") ?? .gmt
        return date.formatted(style)
    }

    /// "1 zdjęcie", "3 zdjęcia", "5 zdjęć".
    static func photos(_ count: Int) -> String {
        "\(count) \(PolishPlural.form(for: count, one: "zdjęcie", few: "zdjęcia", many: "zdjęć"))"
    }

    /// "25 m".
    static func meters(_ distance: CLLocationDistance) -> String {
        "\(Int(distance.rounded())) m"
    }
}
#endif
