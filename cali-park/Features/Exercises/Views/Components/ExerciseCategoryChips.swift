import SwiftUI

// MARK: - ExerciseCategoryChips
/// The category filter above every exercise list: "Wszystkie" and one
/// chip per category, in one horizontally scrolling row.
struct ExerciseCategoryChips: View {
    @Binding var selection: ExerciseCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ExerciseCategoryChip(
                    title: String(localized: "Wszystkie"),
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
/// One filter chip: accent fill when selected.
struct ExerciseCategoryChip: View {
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

#Preview {
    @Previewable @State var selection: ExerciseCategory? = nil
    ExerciseCategoryChips(selection: $selection)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
