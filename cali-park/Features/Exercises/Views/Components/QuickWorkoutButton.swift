import SwiftUI

// MARK: - QuickWorkoutButton
/// Primary "log a whole workout" action, pinned above the tab bar.
struct QuickWorkoutButton: View {
    let action: () -> Void

    var body: some View {
        Button("Szybki trening", systemImage: "bolt.fill", action: action)
            .buttonStyle(.accent)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}
