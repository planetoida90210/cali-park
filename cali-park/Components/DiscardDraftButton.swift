import SwiftUI

// MARK: - DiscardDraftButton
/// The "Anuluj" button of a sheet that holds an unsaved draft. With nothing
/// entered it cancels straight away; with unsaved changes it first asks to
/// discard them ("Odrzuć" / "Wróć"). Pair it with
/// `.interactiveDismissDisabled(hasUnsavedChanges)` on the sheet so a swipe
/// down cannot skip the question.
struct DiscardDraftButton: View {
    let hasUnsavedChanges: Bool
    /// The dialog question, e.g. "Odrzucić trening?".
    let title: String
    /// One line on what gets lost, e.g. "Dodane ćwiczenia nie zostaną zapisane.".
    let message: String
    let onDiscard: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button("Anuluj") {
            if hasUnsavedChanges {
                isConfirming = true
            } else {
                onDiscard()
            }
        }
        .confirmationDialog(title, isPresented: $isConfirming, titleVisibility: .visible) {
            Button("Odrzuć", role: .destructive, action: onDiscard)
            Button("Wróć", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}

// MARK: - Preview
#Preview {
    DiscardDraftButton(
        hasUnsavedChanges: true,
        title: "Odrzucić trening?",
        message: "Dodane ćwiczenia i serie nie zostaną zapisane.",
        onDiscard: {}
    )
    .preferredColorScheme(.dark)
}
