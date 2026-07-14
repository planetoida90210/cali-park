import SwiftUI

// MARK: - ExercisePickerSheet
/// Fast "pick any exercise" sheet: the full catalog with the same search and
/// category filter as the library, but tapping a row calls `onPick` instead of
/// navigating. Used to start logging any exercise in a quick workout.
struct ExercisePickerSheet: View {
    @State private var viewModel = ExerciseLibraryViewModel()
    @FocusState private var searchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    let onPick: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ExercisePickerSearchField(text: $viewModel.searchText, isFocused: $searchFocused)
                    ExercisePickerCategoryChips(selection: $viewModel.selectedCategory)
                    ExercisePickerList(exercises: viewModel.displayedExercises, onPick: pick)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Wybierz ćwiczenie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                        .foregroundStyle(Color.accent)
                }
            }
        }
    }

    private func pick(_ exercise: Exercise) {
        onPick(exercise)
    }
}

// MARK: - ExercisePickerSearchField
private struct ExercisePickerSearchField: View {
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

// MARK: - ExercisePickerCategoryChips
private struct ExercisePickerCategoryChips: View {
    @Binding var selection: ExerciseCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "Wszystkie", isSelected: selection == nil) { selection = nil }

                ForEach(ExerciseCategory.allCases) { category in
                    chip(title: category.displayName, isSelected: selection == category) {
                        selection = category
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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

// MARK: - ExercisePickerList
private struct ExercisePickerList: View {
    let exercises: [Exercise]
    let onPick: (Exercise) -> Void

    var body: some View {
        if exercises.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(Color.accent.opacity(0.8))

                Text("Brak wyników")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(exercises) { exercise in
                    Button {
                        onPick(exercise)
                    } label: {
                        ExercisePickerRow(exercise: exercise)
                    }
                }
            }
        }
    }
}

// MARK: - ExercisePickerRow
private struct ExercisePickerRow: View {
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

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.accent)
        }
        .padding(12)
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExercisePickerSheet { _ in }
                .preferredColorScheme(.dark)
        }
}
