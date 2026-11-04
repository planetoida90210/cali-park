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
                // Not the mode again ("Co 2 dni" is in the stepper): when it
                // comes up next.
                if let upcoming = viewModel.upcomingDays {
                    Text(upcoming)
                }
                if let problem = viewModel.scheduleProblem {
                    Label(problem, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.warning)
                }
            }
        }
    }
}
