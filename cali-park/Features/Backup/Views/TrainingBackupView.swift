import SwiftUI
import UniformTypeIdentifiers

// MARK: - TrainingBackupView
/// "Eksport i import treningów": share everything as one JSON file, or replace
/// everything from one. An import is checked in full and confirmed before
/// anything changes.
struct TrainingBackupView: View {
    @State private var viewModel: TrainingBackupViewModel
    @State private var isPickingFile = false

    init(viewModel: TrainingBackupViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                exportRow
            } header: {
                Text("Eksport")
            } footer: {
                Text("Jeden plik JSON z dziennikiem treningów, planami, testem poziomu, nagrodami, celem tygodniowym oraz ulubionymi Parkami i ćwiczeniami. Zapisz go w Plikach albo wyślij sobie.")
            }
            .listRowBackground(Color.componentBackground)

            Section {
                Button {
                    isPickingFile = true
                } label: {
                    Label("Importuj z pliku", systemImage: "square.and.arrow.down")
                        .foregroundStyle(Color.accent)
                }
                .disabled(viewModel.isImporting)
            } header: {
                Text("Import")
            } footer: {
                Text("Import zastępuje wszystkie dane w apce danymi z pliku. Przed importem zobaczysz, co jest w pliku, i możesz zrezygnować.")
            }
            .listRowBackground(Color.componentBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Eksport i import")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isImporting {
                ProgressView("Importuję…")
                    .padding()
                    .background(Color.componentBackground)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .onAppear { viewModel.prepareExport() }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                viewModel.review(fileAt: url)
            case .failure:
                viewModel.errorMessage = TrainingBackupError.unreadableFile.message
            }
        }
        // An alert, not a confirmation dialog: on iOS 26 the dialog becomes a
        // popover that hides "Anuluj", and replacing every training needs a
        // visible way out.
        .alert(
            "Zastąpić dane w apce?",
            isPresented: pendingBinding,
            presenting: viewModel.pendingImport
        ) { pending in
            Button("Zastąp", role: .destructive) {
                Task { await viewModel.confirmImport(pending) }
            }
            Button("Anuluj", role: .cancel) { viewModel.cancelImport() }
        } message: { pending in
            Text(confirmationMessage(pending))
        }
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("Rozumiem", role: .cancel) {}
        }
        .alert(viewModel.resultMessage ?? "", isPresented: resultBinding) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: Export
    @ViewBuilder
    private var exportRow: some View {
        if let file = viewModel.exportFile {
            ShareLink(item: file) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Eksportuj do pliku", systemImage: "square.and.arrow.up")
                        .foregroundStyle(Color.accent)
                    if let summary = viewModel.currentSummary {
                        Text(summary.text)
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        } else {
            Label("Eksportuj do pliku", systemImage: "square.and.arrow.up")
                .foregroundStyle(Color.textTertiary)
        }
    }

    private func confirmationMessage(_ pending: TrainingBackupViewModel.PendingImport) -> String {
        let current = pending.current.isEmpty ? String(localized: "brak danych") : pending.current.text
        return String(localized: "W pliku: \(pending.incoming.text).\nTeraz w apce: \(current).\n\nDane w apce zostaną zastąpione. Jeśli chcesz je zachować, najpierw je wyeksportuj.")
    }

    // MARK: Bindings
    private var pendingBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingImport != nil },
            set: { if !$0 { viewModel.cancelImport() } }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var resultBinding: Binding<Bool> {
        Binding(
            get: { viewModel.resultMessage != nil },
            set: { if !$0 { viewModel.resultMessage = nil } }
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TrainingBackupView(viewModel: AppEnvironment.skillsVeteran.makeTrainingBackupViewModel())
    }
    .preferredColorScheme(.dark)
}
