import CoreLocation
import Foundation

// MARK: - ParkFormat
/// Polish text and links for Parks.
enum ParkFormat {
    private static let polish = Locale(identifier: "pl_PL")

    /// Required OSM credit (ODbL, OSMF attribution guidelines).
    static let attribution = "© Współtwórcy OpenStreetMap"
    static let copyrightURL = URL(string: "https://www.openstreetmap.org/copyright")!

    /// "350 m" under a kilometre, "1,2 km" under 100 km, "123 km" above.
    static func distance(_ meters: CLLocationDistance) -> String {
        let tens = Int((meters / 10).rounded()) * 10
        if tens < 1000 {
            return "\(max(10, tens)) m"
        }
        let km = meters / 1000
        if km >= 100 {
            return "\(Int(km.rounded())) km"
        }
        return "\(km.formatted(.number.precision(.fractionLength(1)).locale(polish))) km"
    }

    /// "1 Park", "3 Parki", "25 Parków".
    static func parkCount(_ count: Int) -> String {
        "\(count) \(PolishPlural.form(for: count, one: "Park", few: "Parki", many: "Parków"))"
    }

    /// "Dane OSM z 3 lis 2026".
    static func dataDate(_ date: Date) -> String {
        "Dane OSM z \(date.formatted(.dateTime.day().month(.abbreviated).year().locale(polish)))"
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

    /// "52.229700": a dot and no grouping whatever the device locale is.
    private static func coordinate(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(6)).grouping(.never).locale(Locale(identifier: "en_US_POSIX")))
    }
}
