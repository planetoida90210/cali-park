import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let appBackground = Color(hex: "#121212")
    static let componentBackground = Color(hex: "#1E1E1E")
    static let accent = Color(hex: "#D1FF00")  // Updated neon-lime with reduced luminance
    
    // Glass effect background
    static let glassBackground = Color.black.opacity(0.7)
    
    // Card border gradient
    static let cardBorderStart = Color.black.opacity(0.7)
    static let cardBorderEnd = Color.black.opacity(0.4)
    
    // Status colors
    static let statusRed = Color.red
    static let statusOrange = Color.orange
    static let statusGreen = Color.green
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#9A9A9A") // Updated to specified color
    // Tertiary text color (even lighter gray)
    static let textTertiary = Color(hex: "#6C6C6C")
    // Divider line color
    static let divider = Color.white.opacity(0.15)
    
    // Helper to create color from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
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
extension Font {
    // Title fonts - Using SF Rounded when available
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body fonts
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)
    
    // Button fonts
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let buttonMedium = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let buttonSmall = Font.system(size: 13, weight: .semibold, design: .rounded)
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLarge)
            .foregroundColor(.black)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.accent)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLarge)
            .foregroundColor(Color.accent)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.componentBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accent, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// MARK: - Custom Modifiers
struct CardModifier: ViewModifier {
    let withShadow: Bool
    
    init(withShadow: Bool = false) {
        self.withShadow = withShadow
    }
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.componentBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.cardBorderStart, Color.cardBorderEnd]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(withShadow ? 0.2 : 0), radius: withShadow ? 6 : 0)
    }
}

// MARK: - Edit Mode Modifier
struct EditModeStyle: ViewModifier {
    @Environment(\.editMode) private var editMode
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(editMode?.wrappedValue.isEditing == true ? 0.95 : 1)
            .opacity(editMode?.wrappedValue.isEditing == true ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), 
                      value: editMode?.wrappedValue)
    }
}

// Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.glassBackground.blur(radius: 30))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.cardBorderStart, Color.cardBorderEnd]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// Extension to apply modifiers more easily
extension View {
    func cardStyle(withShadow: Bool = false) -> some View {
        modifier(CardModifier(withShadow: withShadow))
    }
    
    func glassCardStyle() -> some View {
        modifier(GlassCardModifier())
    }
    
    func editModeStyle() -> some View {
        modifier(EditModeStyle())
    }
} 
 
