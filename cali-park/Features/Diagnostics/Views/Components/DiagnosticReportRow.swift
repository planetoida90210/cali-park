import SwiftUI

// MARK: - DiagnosticReportRow
/// One report in the list: its kind's icon, title and subtitle.
struct DiagnosticReportRow: View {
    let report: DiagnosticReport

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // At accessibility sizes the icon goes above the text, so the text
        // keeps the row's full width.
        let layout =
            typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
        layout {
            Image(systemName: DiagnosticKindIcon.name(for: report.primaryKind))
                .foregroundStyle(Color.accent)
                .scaledIconFrame(28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(DiagnosticsFormat.title(for: report))
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
                Text(DiagnosticsFormat.subtitle(for: report))
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
