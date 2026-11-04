import SwiftUI

// MARK: - SetPadKeypad
struct SetPadKeypad: View {
    @Binding var input: SetPadInput

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                digitKey(1); digitKey(2); digitKey(3)
            }
            GridRow {
                digitKey(4); digitKey(5); digitKey(6)
            }
            GridRow {
                digitKey(7); digitKey(8); digitKey(9)
            }
            GridRow {
                SetPadKey(label: String(localized: "Usuń"), isEnabled: canDelete) {
                    input.deleteBackward()
                } content: {
                    Image(systemName: "delete.left")
                }

                digitKey(0)

                SetPadKey(label: String(localized: "Dodaj serię"), isAccent: true, isEnabled: input.canCommit) {
                    input.commitSet()
                } content: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var canDelete: Bool {
        !input.currentEntry.isEmpty || !input.committedSets.isEmpty
    }

    private func digitKey(_ digit: Int) -> some View {
        SetPadKey(label: "\(digit)", isEnabled: true) {
            input.appendDigit(digit)
        } content: {
            Text("\(digit)")
        }
    }
}
