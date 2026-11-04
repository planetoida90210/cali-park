import SwiftUI

// MARK: - ProgramFirstPullUpHintSection
/// Points an athlete without a full pull-up to the "Pierwsze podciągnięcie"
/// program.
struct ProgramFirstPullUpHintSection: View {
    var body: some View {
        Section {
            NavigationLink(value: ProgramID.firstPullUp) {
                Label("Nie robisz jeszcze pełnego podciągnięcia? Zacznij od programu Pierwsze podciągnięcie.",
                      systemImage: "lightbulb")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }
            .listRowBackground(Color.componentBackground)
        }
    }
}
