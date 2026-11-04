import SwiftUI

// MARK: - QuickWorkoutBottomBar
/// "Dodaj ćwiczenie" pinned under the workout's list. Its own background runs
/// to the bottom edge, so the list never shows around or under the button.
struct QuickWorkoutBottomBar: View {
    let onAdd: () -> Void

    var body: some View {
        Button("Dodaj ćwiczenie", systemImage: "plus", action: onAdd)
            .buttonStyle(.secondary)
            .accessibilityIdentifier("quickWorkout.addExercise")
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color.appBackground.ignoresSafeArea(edges: .bottom))
    }
}
