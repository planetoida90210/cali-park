import SwiftUI

// MARK: - ProgramBrowserView
/// "Gotowe programy": the list of ready-made programs and each program's
/// detail screen, presented as a sheet from the plan list. Creating a program
/// hands the saved plans back through `onCreated`; the presenter closes the
/// sheet and opens the first plan in the editor.
struct ProgramBrowserView: View {
    let environment: AppEnvironment
    let onCreated: ([WorkoutPlan]) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ProgramListView()
                .navigationTitle("Gotowe programy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Zamknij") { dismiss() }
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .navigationDestination(for: ProgramID.self) { id in
                    if let program = ProgramCatalog.program(withID: id) {
                        ProgramDetailView(
                            viewModel: environment.makeProgramDetailViewModel(program: program),
                            onCreated: onCreated
                        )
                    }
                }
        }
    }
}

// MARK: - ProgramListView
/// Every ready-made program with its tagline, frequency and credit line.
private struct ProgramListView: View {
    var body: some View {
        List {
            Section {
                ForEach(ProgramCatalog.all) { program in
                    NavigationLink(value: program.id) {
                        ProgramRow(program: program)
                    }
                    .accessibilityIdentifier("programs.row.\(program.id.rawValue)")
                    .listRowBackground(Color.componentBackground)
                    .listRowSeparatorTint(Color.divider)
                }
            } footer: {
                Text("Program tworzy zwykły plan, który możesz potem dowolnie zmieniać. Ćwiczenia dopasowują się do Twojego szczebla na drabinach.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - ProgramRow
private struct ProgramRow: View {
    let program: TrainingProgram

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ExerciseIconView(symbolName: program.symbolName, size: .row)

            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)

                Text(program.tagline)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)

                Text("\(program.frequency) · \(program.sessionLength)".keptTogether)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)

                Text(program.creditLine.keptTogether)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    Color.appBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ProgramBrowserView(environment: .seeded()) { _ in }
                .preferredColorScheme(.dark)
        }
}
#endif
