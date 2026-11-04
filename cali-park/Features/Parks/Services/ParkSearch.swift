import CoreLocation
import Foundation

// MARK: - ParkDistance
/// A Park with its distance from the user, when the user's position is known.
struct ParkDistance: Identifiable, Hashable, Sendable {
    let park: Park
    let meters: CLLocationDistance?

    var id: UUID { park.id }
}

// MARK: - ParkSearch
/// Pure filtering and ordering for the Parks map, list and Home module.
enum ParkSearch {
    /// Parks whose name or locality contains every word of `query`. Case,
    /// diacritics and "ł" are ignored, so "lodz" finds "Łódź". An empty query
    /// returns every Park.
    static func matching(_ parks: [Park], query: String) -> [Park] {
        let tokens = normalized(query).split(whereSeparator: \.isWhitespace)
        guard !tokens.isEmpty else { return parks }
        return parks.filter { park in
            let haystack = normalized([
                park.displayName, park.generatedName, park.locality.city ?? "", park.locality.district ?? ""
            ].joined(separator: " "))
            return tokens.allSatisfy { haystack.contains($0) }
        }
    }

    /// Nearest first when `origin` is known. Without a position the order is
    /// by city, then name, and no distance is invented.
    static func ordered(_ parks: [Park], from origin: CLLocationCoordinate2D?) -> [ParkDistance] {
        guard let origin else {
            return parks
                .sorted { lhs, rhs in
                    let lhsCity = lhs.locality.city ?? "", rhsCity = rhs.locality.city ?? ""
                    if lhsCity != rhsCity { return lhsCity.localizedStandardCompare(rhsCity) == .orderedAscending }
                    return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
                }
                .map { ParkDistance(park: $0, meters: nil) }
        }
        return parks
            .map { ParkDistance(park: $0, meters: distance(from: origin, to: $0)) }
            .sorted { ($0.meters ?? 0, $0.park.id.uuidString) < ($1.meters ?? 0, $1.park.id.uuidString) }
    }

    /// The closest Park to `origin`, or nil when there are none.
    static func nearest(_ parks: [Park], to origin: CLLocationCoordinate2D) -> ParkDistance? {
        ordered(parks, from: origin).first
    }

    static func distance(from origin: CLLocationCoordinate2D, to park: Park) -> CLLocationDistance {
        CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: park.latitude, longitude: park.longitude))
    }

    static func normalized(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pl_PL"))
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "l")
    }
}
