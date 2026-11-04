import SwiftUI

// MARK: - Binding+isPresent
extension Binding where Value == String? {
    /// `true` while the message is set. Setting it to `false` (the alert
    /// closing) clears the message; setting it to `true` changes nothing,
    /// because only the owner of the message decides what it says.
    var isPresent: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}

// MARK: - View+errorAlert
extension View {
    /// The app's one error alert: the message is the title, "Rozumiem"
    /// closes it and clears the message.
    ///
    /// - Parameters:
    ///   - message: The view model's optional message; the alert shows while
    ///     it is set.
    ///   - hint: A second line under the title, such as "Spróbuj ponownie.".
    ///   - onDismiss: Runs when "Rozumiem" is tapped, after the alert starts
    ///     closing.
    func errorAlert(
        _ message: Binding<String?>,
        hint: LocalizedStringKey? = nil,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        alert(message.wrappedValue ?? "", isPresented: message.isPresent) {
            Button("Rozumiem", role: .cancel, action: onDismiss)
        } message: {
            if let hint {
                Text(hint)
            }
        }
    }

    /// An error or info alert with its own buttons, for the few alerts that
    /// offer more than "Rozumiem" (e.g. "Spróbuj ponownie"). The alert shows
    /// while `message` is set, and closing it clears the message.
    func messageAlert<Actions: View>(
        _ message: Binding<String?>,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        alert(message.wrappedValue ?? "", isPresented: message.isPresent, actions: actions)
    }
}
