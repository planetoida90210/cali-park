import SwiftUI

// MARK: - ProgramSessionPreviewSection
/// One of the program's sessions on the athlete's current rungs.
struct ProgramSessionPreviewSection: View {
    let plan: WorkoutPlan
    let viewModel: ProgramDetailViewModel

    var body: some View {
        Section {
            ForEach(plan.exercises) { planned in
                ProgramItemRow(
                    exercise: viewModel.exercise(for: planned),
                    target: viewModel.targetSummary(for: planned, in: plan)
                )
                .listRowBackground(Color.componentBackground)
            }
        } header: {
            Text("Trening na Twoich szczeblach")
        } footer: {
            Text("Gdy awansujesz na drabinie, plan przejdzie na nowy szczebel sam.")
        }
    }
}
