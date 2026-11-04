import SwiftUI

// MARK: - PlanExercisesSection
struct PlanExercisesSection: View {
    let viewModel: PlanEditorViewModel
    let onAdd: () -> Void

    var body: some View {
        Section {
            ForEach(viewModel.exercises) { planned in
                PlanExerciseRow(exercise: viewModel.exercise(for: planned),
                                target: viewModel.targetSummary(for: planned),
                                ladder: viewModel.ladderName(for: planned))
                    .listRowBackground(Color.componentBackground)
            }
            .onDelete { viewModel.remove(atOffsets: $0) }

            Button("Dodaj ćwiczenie", systemImage: "plus", action: onAdd)
                .foregroundStyle(Color.accent)
            .listRowBackground(Color.componentBackground)
        } header: {
            Text("Ćwiczenia")
        } footer: {
            if viewModel.exercises.isEmpty {
                Text("Dodaj co najmniej jedno ćwiczenie.")
            }
        }
    }
}
