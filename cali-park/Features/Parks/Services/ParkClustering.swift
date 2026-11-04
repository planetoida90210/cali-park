import CoreLocation
import MapKit

// MARK: - ParkCluster
/// One map annotation: a single Park or a bubble for several close Parks.
nonisolated struct ParkCluster: Identifiable, Hashable, Sendable {
    let parks: [Park]

    /// Stable while the same Parks stay together, so SwiftUI keeps the view.
    var id: String {
        parks.count == 1 ? parks[0].id.uuidString : "\(parks[0].id.uuidString)+\(parks.count)"
    }

    var isSingle: Bool { parks.count == 1 }

    var coordinate: CLLocationCoordinate2D {
        let count = Double(parks.count)
        return CLLocationCoordinate2D(
            latitude: parks.map(\.latitude).reduce(0, +) / count,
            longitude: parks.map(\.longitude).reduce(0, +) / count
        )
    }
}

// MARK: - ParkClustering
/// Grid clustering for SwiftUI `Map`, which has no annotation clustering of its
/// own. The grid is fixed to coordinates (not to the screen), so panning does
/// not reshuffle bubbles; zooming in shrinks the cells and splits them.
nonisolated enum ParkClustering {
    /// Smallest cell, about 20 m: Parks are at least 40 m apart in the data, so
    /// at street zoom every Park is its own pin.
    static let minimumCellDegrees = 0.0002

    /// Clusters for Parks inside `region` (plus a margin, so pins don't pop in
    /// at the edges while panning). `selectedID` always stays a single pin.
    static func clusters(for parks: [Park],
                         in region: MKCoordinateRegion,
                         selectedID: UUID? = nil,
                         cellsAcross: Double = 5) -> [ParkCluster] {
        let visible = expanded(region, by: 1.5)
        let cell = max(region.span.longitudeDelta / cellsAcross, minimumCellDegrees)
        // Degrees of latitude are longer than degrees of longitude in Poland;
        // cos(52°) ≈ 0.62 keeps cells roughly square on screen.
        let latitudeCell = cell * cos(region.center.latitude * .pi / 180)

        var selected: [ParkCluster] = []
        var buckets: [GridKey: [Park]] = [:]
        for park in parks where contains(visible, park) {
            if park.id == selectedID {
                selected.append(ParkCluster(parks: [park]))
                continue
            }
            let key = GridKey(row: Int((park.latitude / latitudeCell).rounded(.down)),
                              column: Int((park.longitude / cell).rounded(.down)))
            buckets[key, default: []].append(park)
        }
        let grouped = mergeNeighbours(Array(buckets.values),
                                      longitudeThreshold: cell * 0.75,
                                      latitudeThreshold: latitudeCell * 0.75)
        let clusters = grouped.map { members in
            ParkCluster(parks: members.sorted { $0.id.uuidString < $1.id.uuidString })
        }
        return (clusters + selected).sorted { $0.id < $1.id }
    }

    /// Grid cells split Parks that sit just either side of a cell edge, and
    /// their bubbles then overlap on screen. Merge groups whose centres are
    /// closer than most of a cell; bigger groups absorb smaller ones.
    private static func mergeNeighbours(_ groups: [[Park]],
                                        longitudeThreshold: Double,
                                        latitudeThreshold: Double) -> [[Park]] {
        let ordered = groups.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return (lhs.map(\.id.uuidString).min() ?? "") < (rhs.map(\.id.uuidString).min() ?? "")
        }
        var merged: [[Park]] = []
        for group in ordered {
            let center = centroid(group)
            if let index = merged.firstIndex(where: { existing in
                let other = centroid(existing)
                return abs(other.latitude - center.latitude) < latitudeThreshold
                    && abs(other.longitude - center.longitude) < longitudeThreshold
            }) {
                merged[index].append(contentsOf: group)
            } else {
                merged.append(group)
            }
        }
        return merged
    }

    private static func centroid(_ parks: [Park]) -> CLLocationCoordinate2D {
        let count = Double(parks.count)
        return CLLocationCoordinate2D(latitude: parks.map(\.latitude).reduce(0, +) / count,
                                      longitude: parks.map(\.longitude).reduce(0, +) / count)
    }

    /// A region that shows every Park in `parks` with some padding.
    static func region(fitting parks: [Park], minimumSpan: CLLocationDegrees = 0.004) -> MKCoordinateRegion? {
        guard let first = parks.first else { return nil }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for park in parks.dropFirst() {
            minLat = min(minLat, park.latitude); maxLat = max(maxLat, park.latitude)
            minLon = min(minLon, park.longitude); maxLon = max(maxLon, park.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.6, minimumSpan),
                                   longitudeDelta: max((maxLon - minLon) * 1.6, minimumSpan))
        )
    }

    // MARK: Private

    private struct GridKey: Hashable {
        let row: Int
        let column: Int
    }

    private static func expanded(_ region: MKCoordinateRegion, by factor: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(center: region.center,
                           span: MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta * factor,
                                                  longitudeDelta: region.span.longitudeDelta * factor))
    }

    private static func contains(_ region: MKCoordinateRegion, _ park: Park) -> Bool {
        abs(park.latitude - region.center.latitude) <= region.span.latitudeDelta / 2
            && abs(park.longitude - region.center.longitude) <= region.span.longitudeDelta / 2
    }
}
