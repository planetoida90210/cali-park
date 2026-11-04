import SwiftUI

// MARK: - PathCalibrationButton
struct PathCalibrationButton: View {
    let action: () -> Void

    var body: some View {
        Button("Ustaw poziom", systemImage: "slider.horizontal.3", action: action)
            .buttonStyle(.secondary(.compact))
    }
}
