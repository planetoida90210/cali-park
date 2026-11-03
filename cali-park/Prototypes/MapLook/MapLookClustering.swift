#if DEBUG
// PROTOTYPE — throwaway. Grid clustering for SwiftUI `Map`, which has no built-in
// annotation clustering (MKMapView does; SwiftUI's Map does not as of iOS 26).

import CoreLocation
import MapKit

struct MapLookCluster: Identifiable {
    let parks: [MapLookPark]

    var id: String { parks.map { String($0.id) }.joined(separator: "-") }

    var coordinate: CLLocationCoordinate2D {
        let lat = parks.map(\.latitude).reduce(0, +) / Double(parks.count)
        let lon = parks.map(\.longitude).reduce(0, +) / Double(parks.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var isSingle: Bool { parks.count == 1 }
}

enum MapLookClustering {
    /// Buckets parks into a grid whose cell is `1 / cellsAcross` of the visible span.
    /// Zooming in shrinks the cells, so clusters split into single pins.
    static func clusters(
        for parks: [MapLookPark],
        span: MKCoordinateSpan,
        cellsAcross: Double = 4.5
    ) -> [MapLookCluster] {
        let cell = max(span.longitudeDelta / cellsAcross, 0.0001)
        let latCell = cell * 0.62 // roughly cos(52°), so cells are square on screen
        var buckets: [String: [MapLookPark]] = [:]
        for park in parks {
            let key = "\(Int((park.latitude / latCell).rounded(.down))):\(Int((park.longitude / cell).rounded(.down)))"
            buckets[key, default: []].append(park)
        }
        return buckets.values
            .map { MapLookCluster(parks: $0.sorted { $0.id < $1.id }) }
            .sorted { $0.id < $1.id }
    }

    /// A region that fits every park in the cluster with some padding.
    static func region(fitting parks: [MapLookPark]) -> MKCoordinateRegion {
        let lats = parks.map(\.latitude)
        let lons = parks.map(\.longitude)
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 2.2, 0.006),
                longitudeDelta: max((maxLon - minLon) * 2.2, 0.006)
            )
        )
    }
}
#endif
