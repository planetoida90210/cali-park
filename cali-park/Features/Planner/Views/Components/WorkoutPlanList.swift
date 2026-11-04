import SwiftUI

// MARK: - WorkoutPlanList
/// The saved plans under the way into "Gotowe programy", with the "Czas na
/// Fundamenty" card on top when it applies. Tap a plan to edit it, swipe to
/// delete it.
struct WorkoutPlanList: View {
    let viewModel: WorkoutPlansViewModel
    let graduation: ProgramGraduationViewModel
    let onMoveOnToFundamentals: () -> Void
    let onBrowsePrograms: () -> Void
    let onEdit: (WorkoutPlan) -> Void

    var body: some View {
        List {
            if let plan = graduation.candidate {
                Section {
                    ProgramGraduationCard(
                        planName: plan.name,
                        isReplacing: graduation.isReplacing,
                        onMoveOn: onMoveOnToFundamentals,
                        onDismiss: { graduation.dismiss() }
                    )
                    .listRowBackground(Color.componentBackground)
                }
            }

            Section {
                Button {
                    onBrowsePrograms()
                } label: {
                    ProgramsEntryRow()
                }
                .accessibilityIdentifier("plans.programs")
                .listRowBackground(Color.componentBackground)
            }

            Section {
                ForEach(viewModel.plans) { plan in
                    Button {
                        onEdit(plan)
                    } label: {
                        WorkoutPlanRow(plan: plan,
                                       summary: viewModel.scheduleSummary(for: plan),
                                       reminder: viewModel.reminderSummary(for: plan))
                    }
                    .listRowBackground(Color.componentBackground)
                    .listRowSeparatorTint(Color.divider)
                    // An explicit "Usuń" in red, instead of `.onDelete`'s
                    // system label.
                    .swipeActions(edge: .trailing) {
                        Button("Usuń", systemImage: "trash", role: .destructive) {
                            Task { await viewModel.delete(plan) }
                        }
                        // The app-wide accent tint would paint it lime.
                        .tint(Color.danger)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}
