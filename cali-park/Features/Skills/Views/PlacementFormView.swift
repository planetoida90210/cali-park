import SwiftUI

// MARK: - PlacementFormView
/// The placement questionnaire: a few rep-count questions, a handful of
/// "can you already do this?" checkboxes. The resistance band is not asked
/// here (ticket 026): it stays a visible option on the ladder, and a band
/// declared earlier is kept on save.
///
/// Shared by the onboarding level test and the in-app calibration sheet so the two never
/// drift apart. It lays out sections only — the caller supplies the scroll
/// container and any title — so it drops cleanly into a paged onboarding screen
/// or a navigation sheet.
struct PlacementFormView: View {
    @Bindable var viewModel: PlacementCalibrationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(viewModel.repQuestions) { question in
                PlacementRepQuestionSection(viewModel: viewModel, question: question)
            }
            PlacementSkillSection(viewModel: viewModel)
        }
        // Pre-fills from the saved placement on first appearance only, so
        // paging back to the level test keeps the answers in progress.
        .onAppear { viewModel.load() }
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    ScrollView {
        PlacementFormView(
            viewModel: PlacementCalibrationViewModel(store: InMemorySkillPlacementStore())
        )
        .padding(16)
    }
    .background(Color.appBackground.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
#endif
