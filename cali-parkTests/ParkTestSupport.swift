import CoreLocation
import Foundation
@testable import cali_park

// MARK: - ParkFixtures
/// Small, hand-placed Parks with fixed IDs. Distances from `warsawCentre`:
/// Mokotów ≈ 2.6 km < Praga ≈ 3.3 km < Kraków ≈ 252 km.
enum ParkFixtures {
    static let mokotowID = UUID(uuidString: "D0000000-0000-4000-8000-000000000001")!
    static let pragaID = UUID(uuidString: "D0000000-0000-4000-8000-000000000002")!
    static let krakowID = UUID(uuidString: "D0000000-0000-4000-8000-000000000003")!
    static let lodzID = UUID(uuidString: "D0000000-0000-4000-8000-000000000004")!

    static let warsawCentre = CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)

    static let mokotow = park(id: mokotowID, latitude: 52.2066, longitude: 21.0187,
                              generatedName: "Street workout · Park Dreszera",
                              city: "Warszawa", district: "Mokotów",
                              equipment: [.horizontalBar, .parallelBars])
    static let praga = park(id: pragaID, latitude: 52.2445, longitude: 21.0545,
                            name: "Street Workout Skaryszak",
                            generatedName: "Street workout · Park Skaryszewski",
                            city: "Warszawa", district: "Praga-Południe",
                            equipment: [.parallelBars, .rings])
    static let krakow = park(id: krakowID, latitude: 50.0614, longitude: 19.9137,
                             generatedName: "Drążki · Park Jordana",
                             city: "Kraków", district: "Krowodrza",
                             equipment: [.horizontalBar])
    static let lodz = park(id: lodzID, latitude: 51.7592, longitude: 19.4560,
                           generatedName: "Poręcze · ul. Piotrkowska",
                           city: "Łódź",
                           equipment: [.dipBench])

    static let all = [mokotow, praga, krakow, lodz]

    static func park(id: UUID = UUID(),
                     latitude: Double,
                     longitude: Double,
                     name: String? = nil,
                     generatedName: String = "Street workout",
                     city: String? = nil,
                     district: String? = nil,
                     equipment: [EquipmentType] = [.horizontalBar],
                     status: ParkStatus = .published) -> Park {
        Park(id: id, latitude: latitude, longitude: longitude, status: status,
             name: name, generatedName: generatedName,
             locality: Locality(city: city, district: district),
             equipment: equipment.map { ParkEquipment(type: $0) })
    }
}
