import SwiftUI

// MARK: - ExerciseVariantPickerView
/// "Which one did you do?" — the base movement first, then its progression
/// variants, each pickable. Pushed from the picker when a movement has variants.
struct ExerciseVariantPickerView: View {
    let movement: Exercise
    /// The base movement followed by its variants.
    let choices: [Exercise]
    let onPick: (Exercise) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(choices) { choice in
                    Button {
                        onPick(choice)
                    } label: {
                        ExercisePickerRowLabel(
                            exercise: choice,
                            subtitle: choice == movement ? "Wersja podstawowa" : choice.category.displayName,
                            opensVariants: false
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Dodaj do treningu")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(movement.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    let pushUps = ExerciseCatalog.exercise(withID: ExerciseCatalog.pushUpsID)!
    NavigationStack {
        ExerciseVariantPickerView(
            movement: pushUps,
            choices: [pushUps] + ExerciseCatalog.variants(of: pushUps.id),
            onPick: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
