import SwiftUI

// MARK: - NearestParkRefreshKey
/// Re-runs the nearest-Park lookup on every bump or authorization change.
struct NearestParkRefreshKey: Equatable {
    let tick: Int
    let authorization: LocationAuthorization
}
