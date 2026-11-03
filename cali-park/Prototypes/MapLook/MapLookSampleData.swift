#if DEBUG
// PROTOTYPE — throwaway. Ticket: docs/wayfinder/calipark-1.0/tickets/011-map-look.md
// Three visual directions for the Parks map, switchable from MapLookPrototypeRoot.
// Launch with the `-PrototypeMapLook` argument. Not compiled into Release builds.

import CoreLocation
import MapKit
import SwiftUI

// MARK: - Equipment

enum MapLookEquipment: String, CaseIterable, Identifiable, Hashable {
    case pullUpBar
    case parallelBars
    case rings
    case wallBars

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pullUpBar: "Drążek"
        case .parallelBars: "Poręcze"
        case .rings: "Kółka"
        case .wallBars: "Drabinki"
        }
    }

    var symbol: String {
        switch self {
        case .pullUpBar: "figure.climbing"
        case .parallelBars: "figure.strengthtraining.functional"
        case .rings: "figure.gymnastics"
        case .wallBars: "stairs"
        }
    }
}

// MARK: - Park

struct MapLookPark: Identifiable, Hashable {
    let id: Int
    let name: String
    let district: String
    let latitude: Double
    let longitude: Double
    let equipment: [MapLookEquipment]
    let rating: Double
    let isLit: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// The equipment shown as the pin glyph: rings beat bars because they are rarer.
    var headlineEquipment: MapLookEquipment {
        if equipment.contains(.rings) { return .rings }
        if equipment.contains(.parallelBars) && equipment.contains(.pullUpBar) { return .parallelBars }
        return equipment.first ?? .pullUpBar
    }

    func distance(from origin: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: origin.latitude, longitude: origin.longitude))
    }
}

// MARK: - Sample data

/// Made-up Parks around central Warsaw. Names and coordinates are hand-written for
/// the prototype and do not come from Google Maps or OpenStreetMap.
enum MapLookSampleData {
    /// Fake "you are here" point near the Palace of Culture, so no location permission is needed.
    static let userLocation = CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0070)

    static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.2315, longitude: 21.0150),
        span: MKCoordinateSpan(latitudeDelta: 0.085, longitudeDelta: 0.085)
    )

    static let parks: [MapLookPark] = [
        MapLookPark(id: 0, name: "Drążki pod Kolumnadą", district: "Śródmieście", latitude: 52.2338, longitude: 21.0021, equipment: [.pullUpBar, .parallelBars, .wallBars], rating: 4.6, isLit: true),
        MapLookPark(id: 1, name: "Street Workout Mirów", district: "Wola", latitude: 52.2371, longitude: 20.9912, equipment: [.pullUpBar, .parallelBars, .rings], rating: 4.8, isLit: true),
        MapLookPark(id: 2, name: "Plac Ćwiczeń Hale", district: "Wola", latitude: 52.2349, longitude: 20.9843, equipment: [.pullUpBar, .wallBars], rating: 4.1, isLit: false),
        MapLookPark(id: 3, name: "Skwer Siłaczy", district: "Śródmieście", latitude: 52.2262, longitude: 21.0124, equipment: [.pullUpBar, .parallelBars], rating: 4.3, isLit: true),
        MapLookPark(id: 4, name: "Poręcze przy Skarpie", district: "Powiśle", latitude: 52.2367, longitude: 21.0236, equipment: [.parallelBars, .pullUpBar, .rings], rating: 4.9, isLit: true),
        MapLookPark(id: 5, name: "Kalisteniczny Zakątek", district: "Powiśle", latitude: 52.2312, longitude: 21.0335, equipment: [.pullUpBar, .parallelBars, .wallBars], rating: 4.4, isLit: false),
        MapLookPark(id: 6, name: "Drążek nad Bulwarem", district: "Powiśle", latitude: 52.2418, longitude: 21.0196, equipment: [.pullUpBar], rating: 3.9, isLit: true),
        MapLookPark(id: 7, name: "Strefa Ruchu Muranów", district: "Muranów", latitude: 52.2457, longitude: 20.9972, equipment: [.pullUpBar, .parallelBars, .wallBars], rating: 4.5, isLit: true),
        MapLookPark(id: 8, name: "Podwórko Mocy", district: "Muranów", latitude: 52.2489, longitude: 21.0048, equipment: [.pullUpBar, .rings], rating: 4.2, isLit: false),
        MapLookPark(id: 9, name: "Drążki na Stawkach", district: "Muranów", latitude: 52.2531, longitude: 20.9934, equipment: [.pullUpBar, .parallelBars], rating: 4.0, isLit: true),
        MapLookPark(id: 10, name: "Siłownia pod Chmurką Cytadela", district: "Żoliborz", latitude: 52.2612, longitude: 21.0021, equipment: [.pullUpBar, .parallelBars, .rings, .wallBars], rating: 4.7, isLit: true),
        MapLookPark(id: 11, name: "Workout Park Plac Wilsona", district: "Żoliborz", latitude: 52.2683, longitude: 20.9861, equipment: [.pullUpBar, .parallelBars], rating: 4.4, isLit: true),
        MapLookPark(id: 12, name: "Drabinki na Woli", district: "Wola", latitude: 52.2296, longitude: 20.9738, equipment: [.wallBars, .pullUpBar], rating: 3.7, isLit: false),
        MapLookPark(id: 13, name: "Kalistenika Ochota", district: "Ochota", latitude: 52.2203, longitude: 20.9861, equipment: [.pullUpBar, .parallelBars, .rings], rating: 4.6, isLit: true),
        MapLookPark(id: 14, name: "Drążki przy Pomniku", district: "Ochota", latitude: 52.2145, longitude: 20.9932, equipment: [.pullUpBar], rating: 3.8, isLit: false),
        MapLookPark(id: 15, name: "Plac Treningowy Pole", district: "Mokotów", latitude: 52.2121, longitude: 21.0063, equipment: [.pullUpBar, .parallelBars, .wallBars], rating: 4.5, isLit: true),
        MapLookPark(id: 16, name: "Poręcze Morskie Oko", district: "Mokotów", latitude: 52.2034, longitude: 21.0198, equipment: [.parallelBars, .pullUpBar], rating: 4.2, isLit: false),
        MapLookPark(id: 17, name: "Drążek Ujazdów", district: "Śródmieście", latitude: 52.2197, longitude: 21.0273, equipment: [.pullUpBar, .rings], rating: 4.3, isLit: true),
        MapLookPark(id: 18, name: "Workout Agrykola", district: "Śródmieście", latitude: 52.2164, longitude: 21.0341, equipment: [.pullUpBar, .parallelBars, .wallBars], rating: 4.6, isLit: true),
        MapLookPark(id: 19, name: "Siłka nad Wisłą Praga", district: "Praga-Północ", latitude: 52.2489, longitude: 21.0419, equipment: [.pullUpBar, .parallelBars], rating: 4.1, isLit: true),
        MapLookPark(id: 20, name: "Drążki Ząbkowska", district: "Praga-Północ", latitude: 52.2536, longitude: 21.0478, equipment: [.pullUpBar, .wallBars], rating: 3.9, isLit: false),
        MapLookPark(id: 21, name: "Street Workout Skaryszak", district: "Praga-Południe", latitude: 52.2422, longitude: 21.0592, equipment: [.pullUpBar, .parallelBars, .rings, .wallBars], rating: 4.8, isLit: true),
        MapLookPark(id: 22, name: "Poręcze Saska Kępa", district: "Praga-Południe", latitude: 52.2319, longitude: 21.0671, equipment: [.parallelBars, .pullUpBar], rating: 4.4, isLit: true),
        MapLookPark(id: 23, name: "Kółka przy Stadionie", district: "Praga-Południe", latitude: 52.2368, longitude: 21.0526, equipment: [.rings, .pullUpBar], rating: 4.0, isLit: true),
        MapLookPark(id: 24, name: "Drążek przy Torze", district: "Ochota", latitude: 52.2252, longitude: 20.9786, equipment: [.pullUpBar, .parallelBars], rating: 3.6, isLit: false),
    ]

    static func sortedByDistance(_ parks: [MapLookPark] = parks) -> [MapLookPark] {
        parks.sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
    }
}

// MARK: - Formatting

enum MapLookFormat {
    private static let polish = Locale(identifier: "pl_PL")

    /// "350 m" under a kilometre, "1,2 km" above.
    static func distance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            let rounded = Int((meters / 10).rounded()) * 10
            return "\(rounded) m"
        }
        let km = (meters / 1000).formatted(.number.precision(.fractionLength(1)).locale(polish))
        return "\(km) km"
    }

    /// Walking time at about 80 m per minute: "6 min pieszo".
    static func walk(_ meters: CLLocationDistance) -> String {
        "\(max(1, Int((meters / 80).rounded()))) min pieszo"
    }

    static func rating(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)).locale(polish))
    }

    /// "1 Park", "3 Parki", "25 Parków".
    static func parks(_ count: Int) -> String {
        "\(count) \(PolishPlural.form(for: count, one: "Park", few: "Parki", many: "Parków"))"
    }
}

// MARK: - Glass helper

extension View {
    /// Liquid Glass on iOS 26, a dark material below that.
    @ViewBuilder
    func mapLookGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}
#endif
