import SwiftUI

// MARK: - PlanScheduleSection
struct PlanScheduleSection: View {
    @Bindable var viewModel: PlanEditorViewModel

    var body: some View {
        Section {
            Picker("Powtarzalność", selection: $viewModel.scheduleMode) {
                ForEach(PlanEditorViewModel.ScheduleMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.componentBackground)

            PlanScheduleDetail(viewModel: viewModel)
        } header: {
            Text("Harmonogram")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(WorkoutScheduleFormatter.summary(viewModel.schedule))
                if let problem = viewModel.scheduleProblem {
                    Label(problem, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.warning)
                }
            }
        }
    }
}
