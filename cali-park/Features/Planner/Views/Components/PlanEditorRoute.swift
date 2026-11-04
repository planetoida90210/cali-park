import SwiftUI

// MARK: - PlanEditorRoute
/// Presents the editor for a new plan or an existing one via `sheet(item:)`,
/// so the sheet opens only once its backing plan is decided.
enum PlanEditorRoute: Identifiable {
    case new
    case edit(WorkoutPlan)
    /// A plan "Utwórz plan" just saved: "Anuluj" deletes it.
    case created(WorkoutPlan)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let plan), .created(let plan): plan.id.uuidString
        }
    }

    var plan: WorkoutPlan? {
        switch self {
        case .new: nil
        case .edit(let plan), .created(let plan): plan
        }
    }

    var isJustCreated: Bool {
        if case .created = self { true } else { false }
    }
}
