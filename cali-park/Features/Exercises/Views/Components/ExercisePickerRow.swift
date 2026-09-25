import SwiftUI

// MARK: - ExercisePickerRow
/// One pickable exercise in the quick-workout picker. A movement with
/// progression variants pushes the variant list (so "Pompki" always asks which
/// push-up was done); anything else is picked straight away. Variants found by
/// search name their parent movement instead of listing muscle groups.
struct ExercisePickerRow: View {
    let exercise: Exercise
    /// The main movement's name when `exercise` is a variant.
    let parentName: String?
    let hasVariants: Bool
    let onPick: (Exercise) -> Void

    var body: some View {
        if hasVariants {
            NavigationLink(value: ExerciseVariantDestination(movement: exercise)) {
                ExercisePickerRowLabel(exercise: exercise, subtitle: subtitle, opensVariants: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Wybierz wariant")
        } else {
            Button {
                onPick(exercise)
            } label: {
                ExercisePickerRowLabel(exercise: exercise, subtitle: subtitle, opensVariants: false)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Dodaj do treningu")
        }
    }

    private var subtitle: String {
        if let parentName {
            return "Wariant: \(parentName)"
        }
        return exercise.muscleGroups.map(\.displayName).joined(separator: " · ")
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        VStack(spacing: 12) {
            ExercisePickerRow(
                exercise: ExerciseCatalog.exercise(withID: ExerciseCatalog.pushUpsID)!,
                parentName: nil,
                hasVariants: true,
                onPick: { _ in }
            )
            ExercisePickerRow(
                exercise: ExerciseCatalog.exercise(withID: ExerciseCatalog.diamondPushUpsID)!,
                parentName: "Pompki",
                hasVariants: false,
                onPick: { _ in }
            )
        }
        .padding(16)
        .background(Color.appBackground)
    }
    .preferredColorScheme(.dark)
}
