import SwiftUI

// MARK: - DiagnosticsRoute
/// Push destination from "Diagnostyka": one report's detail.
nonisolated struct DiagnosticsRoute: Hashable {
    let reportID: UUID
}
