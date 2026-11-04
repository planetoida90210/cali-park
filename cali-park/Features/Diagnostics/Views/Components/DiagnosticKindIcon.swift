import SwiftUI

// MARK: - DiagnosticKindIcon
/// The SF Symbol for a report's main kind.
enum DiagnosticKindIcon {
    static func name(for kind: DiagnosticKind?) -> String {
        switch kind {
        case .crash: "exclamationmark.octagon"
        case .hang: "hourglass"
        case .cpuException: "cpu"
        case .diskWriteException: "internaldrive"
        case .appLaunch: "timer"
        case .metrics: "chart.bar"
        case nil: "doc.text"
        }
    }
}
