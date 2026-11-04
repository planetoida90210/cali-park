import Foundation
import Testing
@testable import cali_park

// MARK: - Opening hours

@Suite("OSM opening hours on the Park card", .timeLimit(.minutes(1)))
struct ParkOpeningHoursTests {
    @Test("Simple forms read as Polish text", arguments: [
        ("24/7", "Całą dobę"),
        ("Mo-Su 06:00-22:00", "Codziennie 6:00–22:00"),
        ("Mo-Fr 10:00-22:00", "Pon.–pt. 10:00–22:00"),
        ("06:00-22:00", "Codziennie 6:00–22:00"),
        ("Mo-Su 00:00-24:00", "Całą dobę"),
        ("00:00-24:00", "Całą dobę"),
        ("Mo-Fr 06:00-22:00; Sa,Su 08:00-20:00", "Pon.–pt. 6:00–22:00; sob., niedz. 8:00–20:00"),
        ("Sa 09:30-14:00", "Sob. 9:30–14:00"),
        ("Mo-Fr 06:00-12:00,14:00-20:00", "Pon.–pt. 6:00–12:00, 14:00–20:00"),
        ("Mo-Fr 06:00-22:00; Su off", "Pon.–pt. 6:00–22:00; niedz. nieczynne"),
        ("Mo-We,Fr 07:00-21:00", "Pon.–śr., pt. 7:00–21:00"),
        ("Mo-Fr 00:00-24:00", "Pon.–pt. całą dobę"),
        ("  24/7 ", "Całą dobę")
    ])
    func simpleForms(raw: String, expected: String) {
        #expect(ParkOpeningHours.text(for: raw) == expected)
        #expect(ParkOpeningHours.translate(raw) == expected)
    }

    @Test("Anything else is shown unchanged, never guessed", arguments: [
        "sunrise-sunset",
        "Mo-Fr 08:00-20:00; PH off",
        "Apr-Oct Mo-Su 06:00-22:00",
        "Mo-Su 6:00-22:00",
        "Mo-Su 06:00-25:00",
        "Su-Mo 06:00-22:00",
        "Mo-Fr 08:00+",
        "dawn-dusk",
        "Mo-Fr 10:00-22:00;",
        "Xx 10:00-12:00",
        "Mo-Su 06:00-22:00 \"wiosną\""
    ])
    func rawFallback(raw: String) {
        #expect(ParkOpeningHours.translate(raw) == nil)
        #expect(ParkOpeningHours.text(for: raw) == raw)
    }

    @Test("Every opening hours value in the bundled snapshot reads as Polish")
    func bundledValuesTranslate() async throws {
        let catalog = try await BundledParkDirectory(bundle: Bundle(for: AppEnvironment.self)).catalog()
        let values = Set(catalog.parks.compactMap(\.openingHours))
        #expect(values.isEmpty == false)
        for value in values {
            #expect(ParkOpeningHours.translate(value) != nil, "\(value)")
        }
    }
}

// MARK: - Equipment and details

@Suite("Park card equipment and details")
struct ParkCardFormatTests {
    private static let richPark = Park(
        id: UUID(uuidString: "D0000000-0000-4000-8000-0000000000A1")!,
        latitude: 50.285, longitude: 18.594,
        osmRefs: ["n13608564606", "w1297344591"],
        generatedName: "Street workout · Skwer Młodego Strażaka",
        locality: Locality(city: "Gliwice", district: "Ostropa"),
        equipment: [ParkEquipment(type: .horizontalBar, count: 7, heights: [.high, .low]),
                    ParkEquipment(type: .parallelBars, count: 2),
                    ParkEquipment(type: .rings),
                    ParkEquipment(type: .wallBars, count: 1),
                    ParkEquipment(type: .sitUp)],
        hasMachines: true,
        surface: .artificialTurf,
        lit: false,
        covered: true,
        access: .customers,
        openingHours: "Mo-Su 06:00-22:00"
    )

    /// A Park as OSM often has it: one pull-up bar and nothing else.
    private static let sparsePark = Park(
        id: UUID(uuidString: "D0000000-0000-4000-8000-0000000000A2")!,
        latitude: 52.23, longitude: 20.97,
        osmRefs: ["w123456"],
        generatedName: "Drążki · ul. Kasprzaka",
        equipment: [ParkEquipment(type: .horizontalBar)]
    )

    @Test("Counts and heights read as Polish, and nothing when OSM is silent")
    func equipmentLines() throws {
        let bar = Self.richPark.equipment[0]
        #expect(ParkFormat.count(bar) == "× 7")
        #expect(ParkFormat.heights(bar) == "niski, wysoki")
        #expect(ParkFormat.equipmentAccessibility(bar) == "Drążek, 7 sztuk, wysokości: niski, wysoki")

        let bars = Self.richPark.equipment[1]
        #expect(ParkFormat.equipmentAccessibility(bars) == "Poręcze, 2 sztuki")

        let rings = Self.richPark.equipment[2]
        #expect(ParkFormat.count(rings) == nil)
        #expect(ParkFormat.heights(rings) == nil)
        #expect(ParkFormat.equipmentAccessibility(rings) == "Kółka")

        let wall = Self.richPark.equipment[3]
        #expect(ParkFormat.equipmentAccessibility(wall) == "Drabinki gimnastyczne, 1 sztuka")
        #expect(ParkFormat.heights(ParkEquipment(type: .horizontalBar, heights: [])) == nil)
    }

    @Test("The compact card names the shown glyphs and counts the rest")
    func equipmentSummary() {
        let equipment = Self.richPark.equipment
        #expect(ParkFormat.equipmentSummary(equipment, shown: 4) == "Sprzęt: Drążek, Poręcze, Kółka, Drabinki gimnastyczne i 1 inny")
        #expect(ParkFormat.equipmentSummary(Array(equipment.prefix(2)), shown: 4) == "Sprzęt: Drążek, Poręcze")
        #expect(ParkFormat.equipmentSummary(equipment, shown: 2) == "Sprzęt: Drążek, Poręcze i 3 inne")
        #expect(ParkFormat.equipmentSummary(Self.sparsePark.equipment, shown: 4) == "Sprzęt: Drążek")
    }

    @Test("Flag support needs a pole or wall bars (012 §3)")
    func flagSupport() {
        #expect(ParkFormat.supportsFlag(Self.richPark))
        #expect(ParkFormat.supportsFlag(Self.sparsePark) == false)
        #expect(ParkFormat.supportsFlag(ParkFixtures.mokotow) == false)
    }

    @Test("Details list every row in order, with readable values")
    func richDetails() {
        let details = ParkFormat.details(for: Self.richPark)
        #expect(details.map(\.id) == [.surface, .lighting, .roof, .access, .openingHours, .machines])
        #expect(details.map(\.label) == ["Nawierzchnia", "Oświetlenie", "Zadaszenie", "Dostęp", "Godziny", "Maszyny siłowni"])
        #expect(details.map(\.value) == ["Sztuczna trawa", "Nie", "Tak", "Tylko dla klientów",
                                         "Codziennie 6:00–22:00", "Tak, obok Parku"])
    }

    @Test("Unknown details stay unknown: no guessed hours or machines")
    func unknownDetails() {
        let details = ParkFormat.details(for: Self.sparsePark)
        let values = Dictionary(uniqueKeysWithValues: details.map { ($0.id, $0.value) })
        #expect(values[.surface] == .some(nil))
        #expect(values[.lighting] == .some(nil))
        #expect(values[.roof] == .some(nil))
        #expect(values[.openingHours] == .some(nil))
        #expect(values[.machines] == .some(nil))
        // Access defaults to public (012 §2).
        #expect(values[.access] == "Dla wszystkich")
        #expect(ParkFormat.unknownDetail == "Brak danych")
    }

    @Test("Every surface has a Polish name")
    func surfaceNames() {
        let titles = ParkSurface.allCases.map(\.title)
        #expect(Set(titles).count == ParkSurface.allCases.count)
        #expect(ParkSurface.rubber.title == "Gumowa")
        #expect(ParkSurface.pavingStones.title == "Kostka brukowa")
    }

    @Test("The OSM link points at the first element", arguments: [
        ("n13608564606", "https://www.openstreetmap.org/node/13608564606"),
        ("w123456", "https://www.openstreetmap.org/way/123456"),
        ("r42", "https://www.openstreetmap.org/relation/42")
    ])
    func osmLink(ref: String, expected: String) {
        var park = Self.sparsePark
        park.osmRefs = [ref, "n1"]
        #expect(ParkFormat.osmURL(for: park)?.absoluteString == expected)
    }

    @Test("No OSM link without a valid ref", arguments: [[String](), ["x12"], ["n"], ["n12a"], ["w-1"]])
    func noOSMLink(refs: [String]) {
        var park = Self.sparsePark
        park.osmRefs = refs
        #expect(ParkFormat.osmURL(for: park) == nil)
    }

    @Test("The subtitle shows the distance only when it is known")
    func subtitle() {
        #expect(ParkFormat.subtitle(for: Self.richPark, distance: 1260) == "Ostropa, Gliwice · 1,3 km")
        #expect(ParkFormat.subtitle(for: Self.richPark, distance: nil) == "Ostropa, Gliwice")
        #expect(ParkFormat.subtitleAccessibility(for: Self.richPark, distance: 350) == "Ostropa, Gliwice, 350 m od Ciebie")
        #expect(ParkFormat.subtitle(for: Self.sparsePark, distance: nil) == nil)
        #expect(ParkFormat.subtitle(for: Self.sparsePark, distance: 80) == "80 m")
    }

    @Test("Badges read their meaning to VoiceOver")
    func badgeAccessibility() {
        #expect(ParkVerification.osm.label == "Z OSM")
        #expect(ParkVerification.osm.accessibilityLabel == "Dane z OpenStreetMap, niesprawdzone przez CaliPark")
        #expect(ParkVerification.verified.label == "Zweryfikowany")
        #expect(ParkVerification.community.label == "Ze Społeczności")
    }
}
