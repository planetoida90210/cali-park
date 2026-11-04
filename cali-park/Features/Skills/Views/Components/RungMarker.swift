import SwiftUI

// MARK: - RungMarker
/// The rail's marker for one rung: a check when conquered, a progress ring on
/// the current rung, a hollow circle ahead.
struct RungMarker: View {
    let displayState: RungDisplayState
    let fraction: Double

    var body: some View {
        switch displayState {
        case .conquered:
            Image(systemName: "checkmark.circle.fill")
                .font(.appTitle3)
                .foregroundStyle(Color.accent)
        case .current:
            ZStack {
                Circle()
                    .stroke(Color.divider, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: max(0.02, fraction))
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)
        case .future:
            Circle()
                .stroke(Color.divider, lineWidth: 2)
                .frame(width: 20, height: 20)
        }
    }
}
