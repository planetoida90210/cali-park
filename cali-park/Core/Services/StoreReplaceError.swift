import Foundation

// MARK: - StoreReplaceError
/// Why a store refused to replace its whole contents.
nonisolated enum StoreReplaceError: Error, Equatable {
    /// The store holds a value but has no way to delete it, so it cannot be
    /// replaced with "nothing saved".
    case cannotDelete
}
