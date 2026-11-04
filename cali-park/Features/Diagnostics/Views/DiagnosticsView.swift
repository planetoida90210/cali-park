import SwiftUI

// MARK: - DiagnosticsView
/// "Diagnostyka" (Profile → "Pomoc i opinie"): the crash and performance
/// reports iOS handed to the app (MetricKit), kept on the phone. The user
/// opens one, sends the ones they choose to support, or deletes them all.
struct DiagnosticsView: View {
    @State private var viewModel: DiagnosticsViewModel
    /// Selection mode ("Wybierz"): rows tick instead of opening. A custom
    /// mode, not `List(selection:)`: in a `NavigationStack` that swallows the
    /// taps meant for the rows' navigation links.
    @State private var isSelecting = false
    @State private var isConfirmingDeleteAll = false
    @State private var mail: MailMessage?

    init(viewModel: DiagnosticsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                if viewModel.reports.isEmpty {
                    if viewModel.hasLoaded {
                        DiagnosticsEmptyState(loadFailed: viewModel.loadFailed)
                    }
                } else {
                    ForEach(viewModel.reports) { report in
                        if isSelecting {
                            selectableRow(report)
                        } else {
                            NavigationLink(value: DiagnosticsRoute(reportID: report.id)) {
                                DiagnosticReportRow(report: report)
                            }
                        }
                    }
                }
            } header: {
                Text("Ostatnie 30 dni")
            } footer: {
                Text("Raporty zostają na tym telefonie. Wysyłasz je tylko Ty, gdy zechcesz.")
            }
            .listRowBackground(Color.componentBackground)

            if isSelecting {
                // In the list, not a bottom toolbar: the tab bar covers that.
                Section {
                    DiagnosticSendButton(
                        title: viewModel.selection.isEmpty ? "Wyślij raport" : "Wyślij (\(viewModel.selection.count))",
                        attachment: viewModel.selectionAttachment,
                        compose: compose
                    )
                    .foregroundStyle(viewModel.selection.isEmpty ? Color.textTertiary : Color.accent)
                } footer: {
                    Text("Zaznacz raporty, które chcesz wysłać.")
                }
                .listRowBackground(Color.componentBackground)
            } else if !viewModel.reports.isEmpty {
                Section {
                    Button("Usuń wszystko", systemImage: "trash", role: .destructive) {
                        isConfirmingDeleteAll = true
                    }
                }
                .listRowBackground(Color.componentBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Diagnostyka")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .navigationDestination(for: DiagnosticsRoute.self) { route in
            if let report = viewModel.report(id: route.reportID) {
                DiagnosticReportDetailView(
                    report: report,
                    attachment: viewModel.attachment(for: [report]),
                    compose: compose,
                    onDelete: { await viewModel.delete(ids: [report.id]) }
                )
            }
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.reports.isEmpty) { _, isEmpty in
            if isEmpty { isSelecting = false }
        }
        .sheet(item: $mail) { message in
            MailComposeView(message: message)
                .ignoresSafeArea()
        }
        // An alert, not a confirmation dialog: on iOS 26 the dialog becomes a
        // popover that hides "Anuluj".
        .alert("Usunąć wszystkie raporty?", isPresented: $isConfirmingDeleteAll) {
            Button("Usuń", role: .destructive) {
                Task { await viewModel.deleteAll() }
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Raporty znikną z telefonu. Tego nie da się cofnąć.")
        }
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("Rozumiem", role: .cancel) {}
        }
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !viewModel.reports.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSelecting ? "Gotowe" : "Wybierz") {
                    withAnimation {
                        isSelecting.toggle()
                        viewModel.selection = []
                    }
                }
            }
        }
    }

    // MARK: Selection
    private func selectableRow(_ report: DiagnosticReport) -> some View {
        let isSelected = viewModel.selection.contains(report.id)
        return Button {
            viewModel.toggleSelection(report.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.appTitle3)
                    .foregroundStyle(isSelected ? Color.accent : Color.textTertiary)
                    .accessibilityHidden(true)
                DiagnosticReportRow(report: report)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Opens the mail composer with the attachment.
    private func compose(_ attachment: DiagnosticAttachment) {
        do {
            mail = try attachment.mailMessage(subject: viewModel.mailSubject)
        } catch {
            viewModel.errorMessage = String(localized: "Nie udało się przygotować raportu do wysłania.")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

#if DEBUG
// MARK: - Preview
#Preview("Raporty") {
    NavigationStack {
        DiagnosticsView(viewModel: AppEnvironment.previewDiagnostics.makeDiagnosticsViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Pusto") {
    NavigationStack {
        DiagnosticsView(viewModel: AppEnvironment.previewEmpty.makeDiagnosticsViewModel())
    }
    .preferredColorScheme(.dark)
}
#endif
