import Foundation

// MARK: - ProgressionPathID
/// Stable identifier for a progression path (one ladder of variations from
/// regression to skill).
///
/// Raw values are durable storage keys: the placement store (SK3) and the
/// onboarding calibration (SK4) key their per-path data on these, so a case's
/// raw value must never change once shipped. Paths are fully independent —
/// nothing here encodes a dependency between them.
enum ProgressionPathID: String, Codable, CaseIterable, Identifiable, Sendable {
    case pullUp
    case row
    case pushUp
    case dip
    case legs
    case core
    case muscleUp
    case lSit
    case frontLever
    case backLever
    case planche
    case humanFlag
    case handstand

    var id: String { rawValue }
}
