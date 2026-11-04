import SwiftUI
import Synchronization
import Testing

@testable import cali_park

/// The one error alert shows while a message is set and clears it on close.
@MainActor
struct ErrorAlertTests {
    /// A binding over a local box, like `$viewModel.errorMessage`.
    /// `Binding` takes `@Sendable` closures, so the box is `Sendable`.
    private final class MessageBox: Sendable {
        private let storage: Mutex<String?>
        init(_ message: String?) { storage = Mutex(message) }
        var message: String? { storage.withLock { $0 } }
        var binding: Binding<String?> {
            Binding(
                get: { self.storage.withLock { $0 } },
                set: { newValue in self.storage.withLock { $0 = newValue } }
            )
        }
    }

    @Test func presentsWhileAMessageIsSet() {
        #expect(MessageBox("Nie udało się zapisać").binding.isPresent.wrappedValue)
        #expect(!MessageBox(nil).binding.isPresent.wrappedValue)
    }

    @Test func closingClearsTheMessage() {
        let box = MessageBox("Nie udało się zapisać")
        box.binding.isPresent.wrappedValue = false
        #expect(box.message == nil)
    }

    @Test func settingTrueKeepsTheMessage() {
        let box = MessageBox("Nie udało się zapisać")
        box.binding.isPresent.wrappedValue = true
        #expect(box.message == "Nie udało się zapisać")

        let empty = MessageBox(nil)
        empty.binding.isPresent.wrappedValue = true
        #expect(empty.message == nil)
    }
}
