import Foundation
import SwiftUI

/// Kodowane, wielokrotnego użytku tagi opisujące cechy parku.
/// Używamy jednego-literowych kodów, aby można było łatwo serializować w backendzie.
/// Enum jest `String` + `Codable` => możemy go wrzucać do JSON-a jako literę.
public enum ParkTag: String, CaseIterable, Codable, Identifiable {
    public var id: String { rawValue }

    case shade = "S"   // Cień / zadrzewienie
    case light = "L"   // Oświetlenie nocą
    case roof  = "C"   // Zadaszenie (cover)
    case water = "F"   // Fontanna / woda (Fountain)
    case parking = "P" // Parking
    case toilet = "R"  // Restroom
    case ground = "B"  // Bezpieczna nawierzchnia (rubber – Base)
    case wind = "W"    // Wietrznie / otwarta przestrzeń

    // Czytelny opis w języku polskim (używany w detalu / tooltipach)
    var descriptionPL: String {
        switch self {
        case .shade:   return "Zacienione miejsce"
        case .light:   return "Oświetlenie nocą"
        case .roof:    return "Zadaszenie / pod mostem"
        case .water:   return "Woda pitna / fontanna"
        case .parking: return "Parking w pobliżu"
        case .toilet:  return "Toalety"
        case .ground:  return "Gumowa nawierzchnia"
        case .wind:    return "Otwarta, wietrzna przestrzeń"
        }
    }

    // Krótka etykieta (<= 6 znaków) do szybkich kapsułek w kafelku
    var shortLabelPL: String {
        switch self {
        case .shade:   return "cień"
        case .light:   return "24 h"
        case .roof:    return "most"
        case .water:   return "woda"
        case .parking: return "parking"
        case .toilet:  return "WC"
        case .ground:  return "guma"
        case .wind:    return "wiatr"
        }
    }

    // Domyślna ikona SF Symbol (fall-back do emoji przy bardzo starych iOS)
    var sfSymbolName: String {
        switch self {
        case .shade:   return "leaf.fill"
        case .light:   return "lightbulb"
        case .roof:    return "building.columns"
        case .water:   return "drop.triangle"
        case .parking: return "parkingsign.circle"
        case .toilet:  return "toilet"
        case .ground:  return "square.dashed"
        case .wind:    return "wind"
        }
    }

    var fallbackEmoji: String {
        switch self {
        case .shade:   return "🌳"
        case .light:   return "💡"
        case .roof:    return "🛖"
        case .water:   return "🚰"
        case .parking: return "🅿️"
        case .toilet:  return "🚻"
        case .ground:  return "🟫"
        case .wind:    return "��"
        }
    }
} 