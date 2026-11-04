import SwiftUI

// MARK: - WeeklyGoalPauseSection
/// Start or end a pause (a week, a month, or through a chosen day, at most 90
/// days). Applies at once, independent of the goals draft.
struct WeeklyGoalPauseSection: View {
    let viewModel: WeeklyGoalEditorViewModel

    @State private var length: Length = .week
    @State private var lastDay: Date

    init(viewModel: WeeklyGoalEditorViewModel) {
        self.viewModel = viewModel
        let range = viewModel.customPauseRange
        let twoWeeks = viewModel.calendar.date(byAdding: .day, value: 13, to: range.lowerBound) ?? range.lowerBound
        _lastDay = State(initialValue: min(twoWeeks, range.upperBound))
    }

    private enum Length: Hashable {
        case week, month, custom
    }

    var body: some View {
        Section {
            if let pause = viewModel.activePause {
                Text(WeeklyGoalFormat.pauseLine(pause, calendar: viewModel.calendar))
                    .foregroundStyle(Color.textPrimary)
                Button("Zakończ pauzę", systemImage: "play.fill") { viewModel.endPause() }
                    .disabled(!viewModel.canEdit)
            } else {
                Picker("Długość", selection: $length) {
                    Text("Tydzień").tag(Length.week)
                    Text("Miesiąc").tag(Length.month)
                    Text("Do wybranego dnia").tag(Length.custom)
                }
                if length == .custom {
                    DatePicker("Ostatni dzień", selection: $lastDay, in: viewModel.customPauseRange, displayedComponents: .date)
                }
                Button("Wstrzymaj cel", systemImage: "pause.fill") { viewModel.startPause(selectedLength) }
                    .disabled(!viewModel.canEdit)
            }
        } header: {
            Text("Pauza")
        } footer: {
            Text(
                """
                Choroba albo wyjazd? Tygodnie pauzy nie liczą się do celu i nie przerywają serii, \
                a cel wykonany mimo pauzy dalej się liczy. Pauza trwa najwyżej \
                \(PolishPlural.days(WeeklyGoalPause.maximumDays)) i kończy się sama.
                """)
        }
    }

    private var selectedLength: WeeklyGoalEditorViewModel.PauseLength {
        switch length {
        case .week: .week
        case .month: .month
        case .custom: .through(lastDay)
        }
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    Form {
        WeeklyGoalPauseSection(viewModel: AppEnvironment.previewEmpty.makeWeeklyGoalEditorViewModel())
    }
    .preferredColorScheme(.dark)
}
#endif
