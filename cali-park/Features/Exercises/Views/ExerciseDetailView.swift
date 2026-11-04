import SwiftUI

// MARK: - ExerciseDetailView
/// Detail screen for a catalog exercise: Watch-style icon, description,
/// muscle groups, equipment, step-by-step instructions and the
/// "Dodaj serię" entry point into the SetPad. The star in the toolbar adds it
/// to the favorites ("Ulubione"), listed first in every exercise picker.
struct ExerciseDetailView: View {
    let exercise: Exercise
    let environment: AppEnvironment

    /// Payload-driven presentation: the sheet opens only when an exercise
    /// is set (never a bare `Bool` + separate state).
    @State private var loggingExercise: Exercise?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ExerciseDetailHeader(exercise: exercise)
                ExerciseMuscleGroupsRow(groups: exercise.muscleGroups)

                if !exercise.equipment.isEmpty {
                    ExerciseEquipmentRow(equipment: exercise.equipment)
                }

                ExerciseInstructionsCard(steps: exercise.instructions)

                ExerciseProgressionsSection(exercise: exercise)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ExerciseFavoriteButton(exercise: exercise, favorites: environment.exerciseFavorites)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Dodaj serię") {
                loggingExercise = exercise
            }
            .buttonStyle(.accent)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color.appBackground.opacity(0.9))
        }
        .sheet(item: $loggingExercise) { exercise in
            SetPadSheetView(viewModel: environment.makeWorkoutLogViewModel(exercise: exercise))
        }
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: ExerciseCatalog.all[0], environment: .seeded())
    }
    .preferredColorScheme(.dark)
}
#endif
