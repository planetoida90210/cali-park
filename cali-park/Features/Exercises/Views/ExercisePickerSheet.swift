import SwiftUI

// MARK: - ExercisePickerSheet
/// Fast "pick any exercise" sheet: the catalog with a pinned search and the
/// library's category filter, but tapping a row calls `onPick` instead of
/// navigating. Searching also finds progression variants; tapping a movement
/// that has variants first asks which one was done. Used to add exercises to
/// a quick workout.
struct ExercisePickerSheet: View {
    @State private var viewModel = ExerciseLibraryViewModel()
    @Environment(\.dismiss) private var dismiss

    let onPick: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ExercisePickerCategoryChips(selection: $viewModel.selectedCategory)
                    ExercisePickerList(viewModel: viewModel, onPick: onPick)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Wybierz ćwiczenie")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Szukaj ćwiczenia lub wariantu"
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                        .foregroundStyle(Color.accent)
                }
            }
            .navigationDestination(for: ExerciseVariantDestination.self) { destination in
                ExerciseVariantPickerView(
                    movement: destination.movement,
                    choices: viewModel.variantChoices(for: destination.movement),
                    onPick: onPick
                )
            }
        }
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
    let viewModel: ExerciseLibraryViewModel
    let onPick: (Exercise) -> Void

    var body: some View {
        let exercises = viewModel.pickerExercises
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
                    ExercisePickerRow(
                        exercise: exercise,
                        parentName: viewModel.parent(of: exercise)?.name,
                        hasVariants: viewModel.hasVariants(exercise),
                        onPick: onPick
                    )
                }
            }
        }
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
