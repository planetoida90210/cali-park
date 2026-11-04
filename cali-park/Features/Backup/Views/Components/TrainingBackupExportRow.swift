import SwiftUI

// MARK: - TrainingBackupExportRow
/// "Eksportuj do pliku": a share link with a summary of what the file holds,
/// or a dimmed label while the file isn't ready.
struct TrainingBackupExportRow: View {
    /// The prepared backup file, or `nil` while it isn't ready.
    let file: URL?
    let summary: TrainingBackupSummary?

    var body: some View {
        if let file {
            ShareLink(item: file) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Eksportuj do pliku", systemImage: "square.and.arrow.up")
                        .foregroundStyle(Color.accent)
                    if let summary {
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
}
