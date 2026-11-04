import SwiftUI

// MARK: - ButtonSize
/// How much room a styled button takes.
enum ButtonSize {
    /// The screen's main action, e.g. pinned above the tab bar or ending a
    /// sheet: `buttonLarge`, 16 pt vertical padding.
    case large
    /// An action inside a card or an empty state: `buttonMedium`, 12 pt
    /// vertical padding.
    case compact

    fileprivate var font: Font { self == .large ? .buttonLarge : .buttonMedium }
    fileprivate var verticalPadding: CGFloat { self == .large ? 16 : 12 }
}

// MARK: - AccentButtonStyle
/// The app's one primary action: the lime accent fill with a black label.
/// Use it for at most one button per screen or card.
struct AccentButtonStyle: ButtonStyle {
    var size: ButtonSize = .large
    /// Stretches to the available width; otherwise hugs the label.
    var fillsWidth = true

    func makeBody(configuration: Configuration) -> some View {
        StyledButtonBody(configuration: configuration, size: size, fillsWidth: fillsWidth, isAccent: true)
    }
}

// MARK: - SecondaryButtonStyle
/// The quieter companion of `AccentButtonStyle` (e.g. "Wróć" next to
/// "Dalej"): accent label and outline on the card color.
struct SecondaryButtonStyle: ButtonStyle {
    var size: ButtonSize = .large
    /// Stretches to the available width; otherwise hugs the label.
    var fillsWidth = true

    func makeBody(configuration: Configuration) -> some View {
        StyledButtonBody(configuration: configuration, size: size, fillsWidth: fillsWidth, isAccent: false)
    }
}

extension ButtonStyle where Self == AccentButtonStyle {
    /// The full-width, large primary action.
    static var accent: AccentButtonStyle { AccentButtonStyle() }

    static func accent(_ size: ButtonSize, fillsWidth: Bool = true) -> AccentButtonStyle {
        AccentButtonStyle(size: size, fillsWidth: fillsWidth)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// The full-width, large secondary action.
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }

    static func secondary(_ size: ButtonSize, fillsWidth: Bool = true) -> SecondaryButtonStyle {
        SecondaryButtonStyle(size: size, fillsWidth: fillsWidth)
    }
}

// MARK: - StyledButtonBody
/// The shared body of both styles. A view rather than a modifier chain, so
/// it can read `isEnabled` and dim a disabled button.
private struct StyledButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let size: ButtonSize
    let fillsWidth: Bool
    let isAccent: Bool

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.medium)
        configuration.label
            .font(size.font)
            .foregroundStyle(isAccent ? Color.black : Color.accent)
            .multilineTextAlignment(.center)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, 24)
            .background(isAccent ? Color.accent : Color.componentBackground, in: shape)
            .overlay {
                if !isAccent {
                    shape.stroke(Color.accent, lineWidth: 1)
                }
            }
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(isEnabled ? (configuration.isPressed ? 0.9 : 1) : 0.5)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        Button("Rozpocznij", systemImage: "play.fill") {}
            .buttonStyle(.accent)
        Button("Dodaj ćwiczenie", systemImage: "plus") {}
            .buttonStyle(.secondary)
        HStack {
            Button("Wróć") {}.buttonStyle(.secondary(.compact))
            Button("Dalej") {}.buttonStyle(.accent(.compact))
        }
        Button("Nowy plan", systemImage: "plus") {}
            .buttonStyle(.accent(.compact, fillsWidth: false))
        Button("Utwórz plan") {}
            .buttonStyle(.accent)
            .disabled(true)
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
