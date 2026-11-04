import SwiftUI

// MARK: - DiagnosticsEmptyState
/// Shown when there are no reports, or why they couldn't be read.
struct DiagnosticsEmptyState: View {
    let loadFailed: Bool

    var body: some View {
        ContentUnavailableView {
            Label("Brak raportów", systemImage: "checkmark.seal")
        } description: {
            Text(
                loadFailed
                    ? DiagnosticsFormat.loadFailureMessage
                    : String(
                        localized:
                            "iOS przekazuje apce raporty o awariach i wydajności mniej więcej raz na dobę. Gdy jakiś przyjdzie, zobaczysz go tutaj."
                    ))
        }
    }
}
