import SwiftUI

// MARK: - StepTrainButton
/// The "Trenuj" call to action pinned to the bottom of the rung detail sheet.
struct StepTrainButton: View {
    let onTrain: () -> Void

    var body: some View {
        Button("Trenuj") {
            onTrain()
        }
        .buttonStyle(.accent)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(Color.appBackground.opacity(0.9))
    }
}
