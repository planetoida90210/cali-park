import SwiftUI

// MARK: - ProgramHeaderSection
struct ProgramHeaderSection: View {
    let program: TrainingProgram
    let schedule: String

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(program.tagline)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                Text(program.audience)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.componentBackground)

            LabeledContent("Jak często", value: program.frequency.keptTogether)
                .listRowBackground(Color.componentBackground)
            LabeledContent("Czas treningu", value: program.sessionLength.keptTogether)
                .listRowBackground(Color.componentBackground)
            LabeledContent("Dni na start", value: schedule)
                .listRowBackground(Color.componentBackground)
        } footer: {
            Text("Dni zmienisz potem w edytorze planu.")
        }
        .foregroundStyle(Color.textPrimary)
    }
}
