import SwiftUI

// MARK: - DiagnosticReportDetailView
/// One report: when it happened, in which build, the key facts and the top
/// of the stack, MetricKit's full JSON, and "Wyślij raport" / "Usuń raport".
struct DiagnosticReportDetailView: View {
    let report: DiagnosticReport
    let attachment: DiagnosticAttachment?
    let compose: (DiagnosticAttachment) -> Void
    let onDelete: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var isConfirmingDelete = false

    var body: some View {
        List {
            Section("Podsumowanie") {
                detail("Data", report.date.formatted(date: .abbreviated, time: .shortened))
                if let version = report.appVersion {
                    detail("Wersja apki", version.text)
                }
                if let os = report.osVersion {
                    detail("System", DiagnosticsFormat.osVersion(os))
                }
                if let device = report.deviceType {
                    detail("Urządzenie", device)
                }
            }
            .listRowBackground(Color.componentBackground)

            ForEach(report.entries.indices, id: \.self) { index in
                entrySection(report.entries[index], number: index + 1)
            }

            Section {
                DisclosureGroup("Pełny raport (JSON)") {
                    Text(payloadPreview)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                        .textSelection(.enabled)
                }
                .tint(Color.accent)
            } footer: {
                Text(
                    report.payload.count > DiagnosticsFormat.previewCharacterLimit
                        ? String(localized: "Podgląd jest skrócony. Wysyłany jest cały raport.")
                        : String(
                            localized: "Dane techniczne od iOS: model telefonu, wersja systemu, ślad stosu. Bez treningów i lokalizacji."))
            }
            .listRowBackground(Color.componentBackground)

            Section {
                DiagnosticSendButton(title: "Wyślij raport", attachment: attachment, compose: compose)
                    .foregroundStyle(Color.accent)
                Button("Usuń raport", systemImage: "trash", role: .destructive) {
                    isConfirmingDelete = true
                }
            }
            .listRowBackground(Color.componentBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(DiagnosticsFormat.title(for: report))
        .navigationBarTitleDisplayMode(.inline)
        .alert("Usunąć ten raport?", isPresented: $isConfirmingDelete) {
            Button("Usuń", role: .destructive) {
                Task {
                    await onDelete()
                    dismiss()
                }
            }
            Button("Anuluj", role: .cancel) {}
        }
    }

    // MARK: Entries
    @ViewBuilder
    private func entrySection(_ entry: DiagnosticEntry, number: Int) -> some View {
        Section {
            ForEach(entry.facts, id: \.key) { fact in
                detail(DiagnosticsFormat.label(for: fact.key), DiagnosticsFormat.value(of: fact))
            }
            if !entry.topFrames.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Szczyt stosu")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                    ForEach(entry.topFrames.indices, id: \.self) { index in
                        Text(verbatim: "\(index)  \(entry.topFrames[index])")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .textSelection(.enabled)
            }
            if entry.facts.isEmpty && entry.topFrames.isEmpty {
                Text("Szczegóły są w pełnym raporcie.")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
        } header: {
            Text(
                report.entries.count > 1
                    ? String(localized: "\(DiagnosticsFormat.title(for: entry.kind)) (\(number) z \(report.entries.count))")
                    : DiagnosticsFormat.title(for: entry.kind))
        }
        .listRowBackground(Color.componentBackground)
    }

    private func detail(_ label: LocalizedStringKey, _ value: String) -> some View {
        detail(Text(label), value)
    }

    private func detail(_ label: String, _ value: String) -> some View {
        detail(Text(label), value)
    }

    private func detail(_ label: Text, _ value: String) -> some View {
        AdaptiveDetailRow {
            label
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
        } details: {
            Text(value)
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                // Stacked under the label at accessibility sizes: align left.
                .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
    }

    private var payloadPreview: String {
        let limit = DiagnosticsFormat.previewCharacterLimit
        guard report.payload.count > limit else { return report.payload }
        return String(report.payload.prefix(limit)) + "\n…"
    }
}

#if DEBUG
// MARK: - Preview
#Preview {
    NavigationStack {
        DiagnosticReportDetailView(
            report: DiagnosticPreviewData.reports[0],
            attachment: nil,
            compose: { _ in },
            onDelete: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif
