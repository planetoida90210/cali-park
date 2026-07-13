import SwiftUI

// MARK: - ExerciseLibraryView
/// Exercises tab: searchable, filterable list of the built-in calisthenics
/// catalog. Rows navigate to `ExerciseDetailView` via `navigationDestination`.
struct ExerciseLibraryView: View {
    @State private var viewModel: ExerciseLibraryViewModel
    @FocusState private var searchFocused: Bool

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: environment.makeExerciseLibraryViewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ExerciseSearchField(text: $viewModel.searchText, isFocused: $searchFocused)
                    ExerciseCategoryChips(selection: $viewModel.selectedCategory)
                    ExerciseListSection(exercises: viewModel.displayedExercises)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Ćwiczenia")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
}

// MARK: - ExerciseSearchField
private struct ExerciseSearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.accent)

            TextField("Szukaj ćwiczenia", text: $text)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .submitLabel(.search)
                .foregroundStyle(Color.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                }
                .accessibilityLabel("Wyczyść wyszukiwanie")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accent.opacity(isFocused.wrappedValue ? 1 : 0.4), lineWidth: 1)
        )
    }
}

// MARK: - ExerciseCategoryChips
private struct ExerciseCategoryChips: View {
    @Binding var selection: ExerciseCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ExerciseCategoryChip(
                    title: "Wszystkie",
                    isSelected: selection == nil
                ) {
                    selection = nil
                }

                ForEach(ExerciseCategory.allCases) { category in
                    ExerciseCategoryChip(
                        title: category.displayName,
                        isSelected: selection == category
                    ) {
                        selection = category
                    }
                }
            }
        }
        .scrollClipDisabled()
    }
}

// MARK: - ExerciseCategoryChip
private struct ExerciseCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bodyMedium)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.accent : Color.componentBackground)
                .foregroundStyle(isSelected ? Color.black : Color.textPrimary)
                .clipShape(.capsule)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - ExerciseListSection
private struct ExerciseListSection: View {
    let exercises: [Exercise]

    var body: some View {
        if exercises.isEmpty {
            ExerciseEmptyState()
                .padding(.top, 48)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(exercises) { exercise in
                    NavigationLink(value: exercise) {
                        ExerciseRowView(exercise: exercise)
                    }
                }
            }
        }
    }
}

// MARK: - ExerciseRowView
private struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ExerciseIconView(symbolName: exercise.symbolName, size: .row)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(exercise.muscleGroups.map(\.displayName).joined(separator: " · "))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - ExerciseEmptyState
private struct ExerciseEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(Color.accent.opacity(0.8))

            Text("Brak wyników")
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Text("Zmień kategorię lub wpisz inną nazwę.")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    ExerciseLibraryView(environment: .preview)
        .preferredColorScheme(.dark)
}
