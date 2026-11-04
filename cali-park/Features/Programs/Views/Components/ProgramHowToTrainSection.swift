import SwiftUI

// MARK: - ProgramHowToTrainSection
/// "Jak trenować": how to progress through the program, with its credit line.
struct ProgramHowToTrainSection: View {
    let program: TrainingProgram

    var body: some View {
        Section {
            ForEach(program.details, id: \.self) { paragraph in
                Text(paragraph)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                    .listRowBackground(Color.componentBackground)
            }
        } header: {
            Text("Jak trenować")
        } footer: {
            Text(program.creditLine.keptTogether)
        }
    }
}
