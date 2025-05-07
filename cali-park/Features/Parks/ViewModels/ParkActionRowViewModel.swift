import SwiftUI
import Combine

// MARK: - ParkActionRowViewModel
/// Handles logic for the Action Row and Floating Action Button behaviour.
final class ParkActionRowViewModel: ObservableObject {
    // MARK: - Public published state
    @Published var showFAB: Bool = false
    @Published var isExpanded: Bool = false

    // MARK: - Dependencies (injected)
    var navigateToPark: () -> Void = {}
    var addWorkoutLog: () -> Void = {}
    var reportProblem: () -> Void = {}

    // MARK: - Scroll handling
    /// Call from parent view when the row's global minY changes.
    func updateRowOffset(_ globalMinY: CGFloat) {
        let threshold: CGFloat = 80 // when row scrolls ~1/2 screen
        let shouldShow = globalMinY < threshold
        // Avoid unnecessary animations if state unchanged
        if shouldShow != showFAB {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showFAB = shouldShow
                // Collapse when becoming visible again
                if !showFAB { isExpanded = false }
            }
        }
    }

    // MARK: - Actions from UI
    func handleNavigate() { navigateToPark() }
    func handleAddLog() { addWorkoutLog() }
    func handleReport() { reportProblem() }

    func toggleFABExpansion() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
} 