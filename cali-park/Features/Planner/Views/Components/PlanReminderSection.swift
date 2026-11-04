import SwiftUI

// MARK: - PlanReminderSection
/// The reminder toggle and its time. Turning it on may show the system
/// permission prompt; when notifications are off, a short note links to the
/// app's notification settings.
struct PlanReminderSection: View {
    @Bindable var viewModel: PlanEditorViewModel

    var body: some View {
        Section {
            Toggle("Przypomnienie", isOn: reminderBinding)
                .tint(Color.accent)
                .foregroundStyle(Color.textPrimary)
                .listRowBackground(Color.componentBackground)

            if viewModel.reminderEnabled {
                DatePicker("Godzina", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    .foregroundStyle(Color.textPrimary)
                    .listRowBackground(Color.componentBackground)
            }
        } footer: {
            if viewModel.showsNotificationsDeniedHint {
                NotificationsDeniedHint()
            } else if viewModel.reminderEnabled {
                Text("Przypomnimy Ci o treningu w zaplanowane dni.")
            }
        }
    }

    /// The toggle shows the new value at once; the view model may turn it
    /// back off when notifications are denied.
    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { viewModel.reminderEnabled },
            set: { enabled in Task { await viewModel.setReminderEnabled(enabled) } }
        )
    }
}
