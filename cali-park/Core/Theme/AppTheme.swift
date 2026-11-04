import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let appBackground = Color(hex: "#121212")
    static let componentBackground = Color(hex: "#1E1E1E")
    // `Color.accent` (#D1FF00, neon-lime) is NOT declared here: it comes from
    // the generated asset symbol for AccentColor.colorset — declaring it again
    // would be an invalid redeclaration.

    // Glass effect background
    static let glassBackground = Color.black.opacity(0.7)

    // Text colors
    static let textPrimary = Color.white
    // The other theme colors come from color sets in the asset catalog, each
    // with a brighter Increase Contrast variant, as generated symbols:
    // - `Color.textSecondary` (#9A9A9A) and `Color.textTertiary` (#8E8E8E):
    //   secondary text, at least 4.5:1 (WCAG AA) on both `appBackground`
    //   and `componentBackground`.
    // - `Color.divider`: hairlines and quiet tracks (white at 15%).
    // - `Color.controlFill`: the fill behind small icon buttons and chips on
    //   cards and glass (white at 8%).
    // - `Color.warning` (orange) and `Color.danger` (red): states and
    //   destructive actions.
    // - `Color.streak`: the streak flame.

    // Helper to create color from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font Extensions
/// The app's type scale: SF Rounded on top of the system text styles, so
/// every token scales with Dynamic Type. At the default text size each one
/// matches the point size it had before (34, 28, 22, 20, 17, 15, 13).
///
/// The titles carry an `app` prefix on purpose: an app-level `Font.title3`
/// would shadow SwiftUI's own, and every `.font(.title3)` would silently
/// resolve to the app token.
extension Font {
    // Titles
    static let appLargeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let appTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let appTitle2 = Font.system(.title2, design: .rounded, weight: .bold)
    static let appTitle3 = Font.system(.title3, design: .rounded, weight: .semibold)

    // Body
    static let bodyLarge = Font.system(.body, design: .rounded)
    static let bodyMedium = Font.system(.subheadline, design: .rounded)
    static let bodySmall = Font.system(.footnote, design: .rounded)

    // Buttons
    static let buttonLarge = Font.system(.body, design: .rounded, weight: .semibold)
    static let buttonMedium = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let buttonSmall = Font.system(.footnote, design: .rounded, weight: .semibold)
}

// MARK: - Corner radii
/// The app's corner radius scale. Small for rows and controls inside a card,
/// medium for cards, buttons and icon squares, large for sheets' cards and
/// overlays.
nonisolated enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 18
}
