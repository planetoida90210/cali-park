import Foundation

// MARK: - SetPadInput
/// Pure, testable state machine behind the SetPad: committed sets plus the
/// digits currently being typed. Mirrors the calculator habit `6+6+6+8+6` —
/// `+` commits the current number as a set, the trailing number (no `+`)
/// still counts when saving.
struct SetPadInput: Equatable {
    /// Reps beyond 999 are not a thing — keeps the display compact.
    static let maxEntryDigits = 3

    private(set) var committedSets: [Int] = []
    private(set) var currentEntry: String = ""

    // MARK: Derived state

    /// The number being typed, or `nil` when the entry is empty.
    var currentValue: Int? {
        Int(currentEntry)
    }

    /// Committed sets plus the pending entry — what a save would persist.
    var setsForSaving: [Int] {
        if let currentValue {
            return committedSets + [currentValue]
        }
        return committedSets
    }

    var totalReps: Int {
        setsForSaving.reduce(0, +)
    }

    /// `+` only makes sense with a non-empty entry (empty commits are blocked).
    var canCommit: Bool {
        currentValue != nil
    }

    var canSave: Bool {
        !setsForSaving.isEmpty
    }

    /// `"6 + 6 + 8"` for the big display; `"0"` when nothing is typed yet.
    var displayText: String {
        var parts = committedSets.map(String.init)
        if !currentEntry.isEmpty {
            parts.append(currentEntry)
        }
        return parts.isEmpty ? "0" : parts.joined(separator: " + ")
    }

    // MARK: Mutations

    mutating func appendDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        guard currentEntry.count < Self.maxEntryDigits else { return }
        // A set of 0 reps is meaningless, so leading zeros are ignored.
        guard !(currentEntry.isEmpty && digit == 0) else { return }
        currentEntry.append(String(digit))
    }

    /// Commits the current entry as a finished set (the `+` key).
    mutating func commitSet() {
        guard let value = currentValue else { return }
        committedSets.append(value)
        currentEntry = ""
    }

    /// Deletes the last typed digit; with an empty entry it undoes the last
    /// committed set instead (the `⌫` key).
    mutating func deleteBackward() {
        if currentEntry.isEmpty {
            guard !committedSets.isEmpty else { return }
            committedSets.removeLast()
        } else {
            currentEntry.removeLast()
        }
    }

    /// Clears everything (the `C` key).
    mutating func clear() {
        committedSets = []
        currentEntry = ""
    }
}
