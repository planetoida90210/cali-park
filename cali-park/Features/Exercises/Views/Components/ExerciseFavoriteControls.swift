import SwiftUI

// MARK: - ExerciseFavoriteLabels
/// The words for adding and removing a favorite exercise, shared by the menu,
/// the VoiceOver action and the detail screen's star.
nonisolated enum ExerciseFavoriteLabels {
    static let add = String(localized: "Dodaj do ulubionych")
    static let remove = String(localized: "Usuń z ulubionych")
    /// Read by VoiceOver on a favorite row.
    static let badge = String(localized: "Ulubione")
    /// Shown above the list until the first favorite exists.
    static let hint = String(localized: "Przytrzymaj ćwiczenie i oznacz je gwiazdką, żeby było na górze.")

    static func title(isFavorite: Bool) -> String { isFavorite ? remove : add }
    static func symbol(isFavorite: Bool) -> String { isFavorite ? "star.slash" : "star" }
}

// MARK: - ExerciseFavoriteActionsModifier
/// Long-press menu and VoiceOver action that add an exercise to the favorites
/// or remove it. Reads `ExerciseFavorites` from the environment (`MainTabView`
/// injects it); without one, e.g. in a bare preview, it adds nothing.
private struct ExerciseFavoriteActionsModifier: ViewModifier {
    let exercise: Exercise

    @Environment(ExerciseFavorites.self) private var favorites: ExerciseFavorites?
    @State private var failureMessage: String?

    func body(content: Content) -> some View {
        if let favorites {
            let isFavorite = favorites.contains(exercise.id)
            content
                .contextMenu {
                    Button(ExerciseFavoriteLabels.title(isFavorite: isFavorite),
                           systemImage: ExerciseFavoriteLabels.symbol(isFavorite: isFavorite)) {
                        toggle(in: favorites)
                    }
                }
                .accessibilityAction(named: ExerciseFavoriteLabels.title(isFavorite: isFavorite)) {
                    toggle(in: favorites)
                }
                .errorAlert($failureMessage)
        } else {
            content
        }
    }

    private func toggle(in favorites: ExerciseFavorites) {
        failureMessage = favorites.toggleReportingFailure(exercise.id)
    }
}

extension View {
    /// Adds "Dodaj do ulubionych" / "Usuń z ulubionych" to a row's long-press
    /// menu and VoiceOver actions.
    func exerciseFavoriteActions(_ exercise: Exercise) -> some View {
        modifier(ExerciseFavoriteActionsModifier(exercise: exercise))
    }
}

// MARK: - ExerciseFavoriteBadge
/// The small star after a favorite's name. VoiceOver reads "Ulubione".
struct ExerciseFavoriteBadge: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.bodySmall)
            .foregroundStyle(Color.accent)
            .accessibilityLabel(ExerciseFavoriteLabels.badge)
    }
}

// MARK: - ExerciseFavoriteButton
/// The star in the exercise detail screen's toolbar.
struct ExerciseFavoriteButton: View {
    let exercise: Exercise
    let favorites: ExerciseFavorites

    @State private var failureMessage: String?

    var body: some View {
        let isFavorite = favorites.contains(exercise.id)
        Button {
            failureMessage = favorites.toggleReportingFailure(exercise.id)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundStyle(Color.accent)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(ExerciseFavoriteLabels.title(isFavorite: isFavorite))
        .sensoryFeedback(.selection, trigger: isFavorite)
        .errorAlert($failureMessage)
    }
}

// MARK: - ExerciseFavoritesHint
/// One small line above an exercise list: how to add a favorite while there
/// is none, or why they are missing when the saved list can't be read.
/// Renders nothing once a favorite exists or while searching.
struct ExerciseFavoritesHint: View {
    let isSearching: Bool

    @Environment(ExerciseFavorites.self) private var favorites: ExerciseFavorites?

    var body: some View {
        if let favorites, !isSearching {
            if favorites.loadFailure != nil {
                line(ExerciseFavorites.loadFailureMessage, symbol: "exclamationmark.triangle")
            } else if favorites.ids.isEmpty {
                line(ExerciseFavoriteLabels.hint, symbol: "star")
            }
        }
    }

    private func line(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.bodySmall)
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview {
    let environment = AppEnvironment.seeded(favoriteExercises: [ExerciseCatalog.pullUpsID])
    let exercise = ExerciseCatalog.exercise(withID: ExerciseCatalog.pullUpsID) ?? ExerciseCatalog.all[0]
    VStack(alignment: .leading, spacing: 16) {
        ExerciseFavoritesHint(isSearching: false)
        HStack {
            Text(exercise.name)
            ExerciseFavoriteBadge()
            Spacer()
            ExerciseFavoriteButton(exercise: exercise, favorites: environment.exerciseFavorites)
        }
    }
    .padding()
    .background(Color.appBackground)
    .environment(environment.exerciseFavorites)
    .preferredColorScheme(.dark)
}
