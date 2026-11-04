import SwiftUI

// MARK: - PlanScheduleDetail
/// The schedule's own control under the mode picker: weekday toggles, the
/// day interval, or the one-off date.
struct PlanScheduleDetail: View {
    @Bindable var viewModel: PlanEditorViewModel

    var body: some View {
        switch viewModel.scheduleMode {
        case .weekly:
            WeekdaySelector(selected: viewModel.selectedWeekdays) { viewModel.toggle($0) }
                .listRowBackground(Color.componentBackground)
        case .everyNDays:
            Stepper(value: $viewModel.interval, in: 1...30) {
                Text(viewModel.interval == 1 ? "Codziennie" : "Co \(PolishPlural.days(viewModel.interval))")
                    .foregroundStyle(Color.textPrimary)
            }
            .listRowBackground(Color.componentBackground)
        case .once:
            DatePicker("Data", selection: $viewModel.onceDate, in: viewModel.earliestOnceDate..., displayedComponents: .date)
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)
        }
    }
}
