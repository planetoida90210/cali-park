import SwiftUI

// MARK: - ExerciseVariantPickerView
/// "Which one did you do?" — the base movement first, then its progression
/// variants, each pickable. Pushed from the picker when a movement has variants.
/// Long-press a variant to make it a favorite, so the next pick is one tap
/// from the top of the picker.
struct ExerciseVariantPickerView: View {
    let movement: Exercise
    /// The base movement followed by its variants.
    let choices: [Exercise]
    let onPick: (Exercise) -> Void

    @Environment(ExerciseFavorites.self) private var favorites: ExerciseFavorites?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(choices) { choice in
                    Button {
                        onPick(choice)
                    } label: {
                        ExercisePickerRowLabel(
                            exercise: choice,
                            subtitle: choice == movement ? String(localized: "Wersja podstawowa") : choice.category.displayName,
                            opensVariants: false,
                            isFavorite: favorites?.contains(choice.id) ?? false
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Dodaj do treningu")
                    .accessibilityIdentifier("exerciseVariant.\(choice.id.uuidString)")
                    .exerciseFavoriteActions(choice)
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

#if DEBUG
// MARK: - Preview
#Preview {
    let pushUps = ExerciseCatalog.exercise(withID: ExerciseCatalog.pushUpsID)!
    let environment = AppEnvironment.seeded(favoriteExercises: [ExerciseCatalog.diamondPushUpsID])
    NavigationStack {
        ExerciseVariantPickerView(
            movement: pushUps,
            choices: [pushUps] + ExerciseCatalog.variants(of: pushUps.id),
            onPick: { _ in }
        )
    }
    .environment(environment.exerciseFavorites)
    .preferredColorScheme(.dark)
}
#endif
