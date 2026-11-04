import CoreLocation
import Foundation

// MARK: - ParkDetail
/// One row of the card's "Szczegóły" section.
nonisolated struct ParkDetail: Identifiable, Hashable, Sendable {
    enum Kind: String, Hashable, Sendable {
        case surface, lighting, roof, access, openingHours, machines
    }

    let id: Kind
    /// Readable value; nil when the data doesn't say.
    let value: String?

    var label: String {
        switch id {
        case .surface: String(localized: "Nawierzchnia")
        case .lighting: String(localized: "Oświetlenie")
        case .roof: String(localized: "Zadaszenie")
        case .access: String(localized: "Dostęp")
        case .openingHours: String(localized: "Godziny")
        case .machines: String(localized: "Maszyny siłowni")
        }
    }

    var symbol: String {
        switch id {
        case .surface: "square.grid.3x3.fill"
        case .lighting: "lightbulb.fill"
        case .roof: "umbrella.fill"
        case .access: "person.2.fill"
        case .openingHours: "clock.fill"
        case .machines: "figure.indoor.cycle"
        }
    }
}
