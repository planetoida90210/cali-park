import SwiftUI

// MARK: - ExerciseLibraryList
struct ExerciseLibraryList: View {
    let sections: [ExerciseListSection]
    let favorites: ExerciseFavorites

    var body: some View {
        if sections.isEmpty {
            ExerciseEmptyState()
                .padding(.top, 48)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(sections) { section in
                    if let title = section.title {
                        ExerciseListSectionHeader(title: title)
                    }
                    ForEach(section.exercises) { exercise in
                        NavigationLink(value: exercise) {
                            ExerciseRowView(exercise: exercise, isFavorite: favorites.contains(exercise.id))
                        }
                        .exerciseFavoriteActions(exercise)
                    }
                }
            }
        }
    }
}
