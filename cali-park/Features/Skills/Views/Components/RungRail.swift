import SwiftUI

// MARK: - RungRail
/// The timeline column: a marker per rung joined by a continuous line. The
/// connectors meet the marker at its edges and stop there — never crossing over
/// it — so every marker reads cleanly, filled or hollow. The line runs accent up
/// to the conquered rungs and dims beyond.
struct RungRail: View {
    let displayState: RungDisplayState
    let fraction: Double
    let isFirst: Bool
    let isLast: Bool

    /// Gap from the top of the rail down to the marker, matched to the card's
    /// own top padding so the marker lines up with the rung's title.
    private let markerTopInset: CGFloat = 12

    private var lineColor: Color {
        displayState == .conquered ? Color.accent : Color.divider
    }

    var body: some View {
        VStack(spacing: 0) {
            connector
                .frame(height: markerTopInset)
                .opacity(isFirst ? 0 : 1)

            RungMarker(displayState: displayState, fraction: fraction)

            connector
                .frame(maxHeight: .infinity)
                .opacity(isLast ? 0 : 1)
        }
        .frame(width: 28)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var connector: some View {
        Rectangle()
            .fill(lineColor)
            .frame(width: 2)
    }
}
